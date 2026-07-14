using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers.Admin;

[Authorize(Roles = "Admin")]
[Route("api/admin/skills")]
[ApiController]
public class AdminSkillsController : ControllerBase
{
    private readonly SmartStepsDbContext _context;

    public AdminSkillsController(SmartStepsDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetSkills()
    {
        var skills = await _context.Skills
            .OrderBy(s => s.Name)
            .Select(s => new {
                s.SkillId, s.Name, s.Description,
                UsageCount = s.SituationSkills.Count
            })
            .ToListAsync();
        return Ok(skills);
    }

    [HttpPost]
    public async Task<IActionResult> CreateSkill([FromBody] SkillDto dto)
    {
        var skill = new Skill
        {
            Name = dto.Name,
            Description = dto.Description
        };
        _context.Skills.Add(skill);
        await _context.SaveChangesAsync();
        return Ok(skill);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSkill(int id, [FromBody] SkillDto dto)
    {
        var skill = await _context.Skills.FindAsync(id);
        if (skill == null) return NotFound();

        skill.Name = dto.Name;
        skill.Description = dto.Description;
        await _context.SaveChangesAsync();
        return Ok(skill);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSkill(int id)
    {
        var skill = await _context.Skills
            .Include(s => s.SituationSkills)
            .FirstOrDefaultAsync(s => s.SkillId == id);
            
        if (skill == null) return NotFound();

        if (skill.SituationSkills.Any())
        {
            return BadRequest(new { Message = "Cannot delete Skill because it is used in Situations." });
        }

        _context.Skills.Remove(skill);
        await _context.SaveChangesAsync();
        return Ok(new { Message = "Skill deleted successfully." });
    }
}

public class SkillDto
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
}
