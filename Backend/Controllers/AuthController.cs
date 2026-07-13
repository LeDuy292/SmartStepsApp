using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;
using SmartStepsServer.Data.DTOs;

namespace SmartStepsServer.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly SmartStepsDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly SmartStepsServer.Services.IEmailService _emailService;

    public AuthController(SmartStepsDbContext context, IConfiguration configuration, SmartStepsServer.Services.IEmailService emailService)
    {
        _context = context;
        _configuration = configuration;
        _emailService = emailService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (await _context.Users.AnyAsync(u => u.Email == request.Email))
        {
            return BadRequest(new { Message = "Email is already in use." });
        }

        var user = new User
        {
            FullName = request.FullName,
            Email = request.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = request.Role,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "User registered successfully." });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
        {
            return Unauthorized(new { Message = "Invalid email or password." });
        }

        var token = GenerateJwtToken(user);
        
        return Ok(new AuthResponse
        {
            Token = token,
            UserId = user.UserId,
            Email = user.Email,
            FullName = user.FullName,
            Role = user.Role
        });
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
    {
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings()
            {
                Audience = new List<string>() { _configuration["GoogleAuth:ClientId"]! }
            };

            var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, settings);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == payload.Email);

            if (user == null)
            {
                // Create user if not exists
                user = new User
                {
                    FullName = payload.Name,
                    Email = payload.Email,
                    Password = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()), // Random password for google users
                    Role = string.IsNullOrEmpty(request.Role) ? "Child" : request.Role, // Default to Child or requested role
                    CreatedAt = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var token = GenerateJwtToken(user);

            return Ok(new AuthResponse
            {
                Token = token,
                UserId = user.UserId,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { Message = "Invalid Google token." });
        }
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null)
        {
            return Ok(new { Message = "If the email is registered, a new password will be sent." });
        }

        var newPassword = Guid.NewGuid().ToString().Substring(0, 8);
        user.Password = BCrypt.Net.BCrypt.HashPassword(newPassword);
        
        await _context.SaveChangesAsync();

        var emailBody = $@"
            <h3>Quên Mật Khẩu</h3>
            <p>Chào bạn,</p>
            <p>Mật khẩu mới của bạn là: <strong>{newPassword}</strong></p>
            <p>Vui lòng đăng nhập lại ứng dụng bằng mật khẩu này nhé.</p>
        ";

        try
        {
            await _emailService.SendEmailAsync(user.Email, "Mật khẩu mới của bạn - SmartSteps", emailBody);
        }
        catch (Exception)
        {
            return StatusCode(500, new { Message = "Lỗi khi gửi email." });
        }

        return Ok(new { Message = "New password has been sent." });
    }

    private string GenerateJwtToken(User user)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!);
        
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("UserId", user.UserId.ToString())
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(7),
            Issuer = _configuration["Jwt:Issuer"],
            Audience = _configuration["Jwt:Audience"],
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }
}
