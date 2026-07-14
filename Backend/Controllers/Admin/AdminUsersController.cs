using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers.Admin;

[Authorize(Roles = "Admin")]
[Route("api/admin/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly SmartStepsDbContext _context;

    public UsersController(SmartStepsDbContext context)
    {
        _context = context;
    }

    // GET: api/admin/users
    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] int page = 1, [FromQuery] int limit = 20, [FromQuery] string? search = null, [FromQuery] string? role = null, [FromQuery] string? status = null)
    {
        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(u => u.FullName.ToLower().Contains(search.ToLower()) || u.Email.ToLower().Contains(search.ToLower()));
        }

        if (!string.IsNullOrEmpty(role))
        {
            query = query.Where(u => u.Role == role);
        }

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(u => u.Status == status);
        }

        var totalItems = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalItems / (double)limit);

        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * limit)
            .Take(limit)
            .Select(u => new
            {
                u.UserId,
                u.FullName,
                u.Email,
                u.Role,
                u.Status,
                u.CreatedAt,
                u.UpdatedAt
            })
            .ToListAsync();

        return Ok(new
        {
            TotalItems = totalItems,
            TotalPages = totalPages,
            CurrentPage = page,
            Users = users
        });
    }

    // GET: api/admin/users/5
    [HttpGet("{id}")]
    public async Task<IActionResult> GetUser(int id)
    {
        var user = await _context.Users
            .Select(u => new
            {
                u.UserId,
                u.FullName,
                u.Email,
                u.Role,
                u.Status,
                u.CreatedAt,
                u.UpdatedAt,
                ProgressCount = u.UserProgresses.Count,
                AnswersCount = u.UserAnswers.Count
            })
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        return Ok(user);
    }

    // POST: api/admin/users
    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserDto dto)
    {
        if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
        {
            return BadRequest(new { Message = "Email is already in use." });
        }

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = dto.Role,
            Status = dto.Status ?? "Active",
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetUser), new { id = user.UserId }, new { Message = "User created successfully." });
    }

    // PUT: api/admin/users/5
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        if (dto.Email != user.Email && await _context.Users.AnyAsync(u => u.Email == dto.Email))
        {
            return BadRequest(new { Message = "Email is already in use." });
        }

        // Prevent admin from changing their own role if they are the only admin
        if (user.Role == "Admin" && dto.Role != "Admin")
        {
            var adminCount = await _context.Users.CountAsync(u => u.Role == "Admin" && u.Status == "Active");
            if (adminCount <= 1)
            {
                return BadRequest(new { Message = "Cannot change role of the only active admin." });
            }
        }

        user.FullName = dto.FullName;
        user.Email = dto.Email;
        user.Role = dto.Role;
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return Ok(new { Message = "User updated successfully." });
    }

    // POST: api/admin/users/5/lock
    [HttpPost("{id}/lock")]
    public async Task<IActionResult> LockUser(int id, [FromBody] LockReasonDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        // Prevent locking the only admin
        if (user.Role == "Admin")
        {
            var adminCount = await _context.Users.CountAsync(u => u.Role == "Admin" && u.Status == "Active");
            if (adminCount <= 1)
            {
                return BadRequest(new { Message = "Cannot lock the only active admin." });
            }
        }

        user.Status = "Locked";
        user.UpdatedAt = DateTime.UtcNow;
        // Optionally store the lock reason somewhere if we had a field/table for it
        
        await _context.SaveChangesAsync();
        return Ok(new { Message = "User locked successfully." });
    }

    // POST: api/admin/users/5/unlock
    [HttpPost("{id}/unlock")]
    public async Task<IActionResult> UnlockUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        user.Status = "Active";
        user.UpdatedAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();
        return Ok(new { Message = "User unlocked successfully." });
    }

    // POST: api/admin/users/5/reset-password
    [HttpPost("{id}/reset-password")]
    public async Task<IActionResult> ResetPassword(int id, [FromServices] SmartStepsServer.Services.IEmailService emailService)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        var newPassword = Guid.NewGuid().ToString().Substring(0, 8);
        user.Password = BCrypt.Net.BCrypt.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync();

        var emailBody = $@"
            <h3>Đặt lại mật khẩu</h3>
            <p>Chào {user.FullName},</p>
            <p>Mật khẩu mới của bạn là: <strong>{newPassword}</strong></p>
            <p>Vui lòng đăng nhập và đổi mật khẩu trong lần tiếp theo.</p>
        ";

        try
        {
            await emailService.SendEmailAsync(user.Email, "Mật khẩu mới - SmartSteps", emailBody);
        }
        catch (Exception)
        {
            // Log exception
        }

        return Ok(new { Message = "Password reset successfully." });
    }

    // DELETE: api/admin/users/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users
            .Include(u => u.UserProgresses)
            .Include(u => u.UserAnswers)
            .Include(u => u.PremiumPayments)
            .FirstOrDefaultAsync(u => u.UserId == id);

        if (user == null)
        {
            return NotFound(new { Message = "User not found." });
        }

        if (user.Role == "Admin")
        {
            var adminCount = await _context.Users.CountAsync(u => u.Role == "Admin" && u.Status != "Inactive");
            if (adminCount <= 1)
            {
                return BadRequest(new { Message = "Cannot delete the only admin." });
            }
        }

        bool hasData = user.UserProgresses.Any() || user.UserAnswers.Any() || user.PremiumPayments.Any();

        if (hasData)
        {
            // Soft delete
            user.Status = "Inactive";
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new { Message = "User has data. Soft deleted (Inactive) instead." });
        }
        else
        {
            // Hard delete
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "User deleted completely." });
        }
    }
}

public class CreateUserDto
{
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string Role { get; set; } = null!;
    public string? Status { get; set; }
}

public class UpdateUserDto
{
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Role { get; set; } = null!;
}

public class LockReasonDto
{
    public string Reason { get; set; } = "";
}
