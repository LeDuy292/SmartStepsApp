using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers;

[ApiController]
[Authorize]
[Route("api/profile")]
public sealed class ProfileController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Forbid();
        var profileJson = await dbContext.Users.AsNoTracking()
            .Where(user => user.UserId == userId)
            .Select(user => user.ProfileJson)
            .SingleOrDefaultAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(profileJson))
            return NotFound(new { message = "Profile has not been completed." });
        return Content(profileJson, "application/json");
    }

    [HttpPut]
    public async Task<IActionResult> Put([FromBody] JsonElement profile, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Forbid();
        if (profile.ValueKind != JsonValueKind.Object)
            return BadRequest(new { message = "Profile must be a JSON object." });
        var user = await dbContext.Users.SingleOrDefaultAsync(item => item.UserId == userId, cancellationToken);
        if (user is null) return NotFound();
        user.ProfileJson = profile.GetRawText();
        if (profile.TryGetProperty("childName", out var name))
        {
            var fullName = name.GetString()?.Trim();
            if (!string.IsNullOrWhiteSpace(fullName)) user.FullName = fullName[..Math.Min(fullName.Length, 100)];
        }
        user.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private bool TryGetUserId(out int userId) => int.TryParse(
        User.FindFirstValue("UserId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier), out userId);
}
