using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Data.DTOs;

public class LoginRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = null!;

    [Required]
    public string Password { get; set; } = null!;
}

public class RegisterRequest
{
    [Required]
    public string FullName { get; set; } = null!;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = null!;

    [Required]
    public string Password { get; set; } = null!;

    [Required]
    [RegularExpression("^(Child|Parent|Admin|ContentCreator)$")]
    public string Role { get; set; } = null!;
}

public class GoogleLoginRequest
{
    [Required]
    public string IdToken { get; set; } = null!;
    
    // Optional role if the user is registering via Google for the first time
    public string? Role { get; set; }
}

public class AuthResponse
{
    public string Token { get; set; } = null!;
    public int UserId { get; set; }
    public string Email { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Role { get; set; } = null!;
}

public class ForgotPasswordRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = null!;
}
