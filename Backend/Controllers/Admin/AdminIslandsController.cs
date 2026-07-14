using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers.Admin;

[Authorize(Roles = "Admin")]
[Route("api/admin/islands")]
[ApiController]
public class AdminIslandsController : ControllerBase
{
    private readonly SmartStepsDbContext _context;

    public AdminIslandsController(SmartStepsDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetIslands()
    {
        var islands = await _context.Islands
            .OrderBy(i => i.OrderIndex)
            .Select(i => new {
                i.IslandId, i.Name, i.Description, i.ImageUrl, i.OrderIndex, i.Status, i.CreatedAt, i.UpdatedAt,
                SituationCount = i.Situations.Count
            })
            .ToListAsync();
        return Ok(islands);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetIsland(int id)
    {
        var island = await _context.Islands.FindAsync(id);
        if (island == null) return NotFound();
        return Ok(island);
    }

    [HttpPost]
    public async Task<IActionResult> CreateIsland([FromBody] IslandDto dto)
    {
        var island = new Island
        {
            Name = dto.Name,
            Description = dto.Description,
            ImageUrl = dto.ImageUrl,
            OrderIndex = dto.OrderIndex,
            Status = dto.Status,
            CreatedAt = DateTime.UtcNow
        };
        _context.Islands.Add(island);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetIsland), new { id = island.IslandId }, island);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateIsland(int id, [FromBody] IslandDto dto)
    {
        var island = await _context.Islands.FindAsync(id);
        if (island == null) return NotFound();

        island.Name = dto.Name;
        island.Description = dto.Description;
        island.ImageUrl = dto.ImageUrl;
        island.OrderIndex = dto.OrderIndex;
        island.Status = dto.Status;
        island.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return Ok(island);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteIsland(int id)
    {
        var island = await _context.Islands
            .Include(i => i.Situations)
            .FirstOrDefaultAsync(i => i.IslandId == id);
        
        if (island == null) return NotFound();

        if (island.Situations.Any())
        {
            return BadRequest(new { Message = "Cannot delete Island because it contains Situations. Please set it to Hidden instead." });
        }

        _context.Islands.Remove(island);
        await _context.SaveChangesAsync();
        return Ok(new { Message = "Island deleted successfully." });
    }
}

public class IslandDto
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int OrderIndex { get; set; }
    public string Status { get; set; } = "Active";
}
