using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers.Admin;

[Authorize(Roles = "Admin")]
[Route("api/admin/situations")]
[ApiController]
public class AdminSituationsController : ControllerBase
{
    private readonly SmartStepsDbContext _context;

    public AdminSituationsController(SmartStepsDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetSituations([FromQuery] int? islandId = null)
    {
        var query = _context.Situations.Include(s => s.Island).AsQueryable();
        
        if (islandId.HasValue)
        {
            query = query.Where(s => s.IslandId == islandId);
        }

        var situations = await query
            .OrderBy(s => s.IslandId).ThenBy(s => s.OrderIndex)
            .Select(s => new {
                s.SituationId, s.Title, s.Intro, s.OrderIndex, s.Status, s.CreatedAt, s.UpdatedAt,
                IslandName = s.Island.Name,
                StepCount = s.SituationSteps.Count,
                FlashcardCount = s.Flashcards.Count
            })
            .ToListAsync();
            
        return Ok(situations);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetSituation(int id)
    {
        var situation = await _context.Situations
            .Include(s => s.SituationSteps)
            .Include(s => s.Flashcards)
            .Include(s => s.SituationSkills).ThenInclude(ss => ss.Skill)
            .FirstOrDefaultAsync(s => s.SituationId == id);
            
        if (situation == null) return NotFound();

        var dto = new {
            situation.SituationId,
            situation.IslandId,
            situation.Title,
            situation.Intro,
            situation.OrderIndex,
            situation.Status,
            situation.CreatedAt,
            situation.UpdatedAt,
            Steps = situation.SituationSteps.OrderBy(st => st.OrderIndex).ToList(),
            Flashcards = situation.Flashcards.ToList(),
            Skills = situation.SituationSkills.Select(ss => new { ss.Skill.SkillId, ss.Skill.Name }).ToList()
        };

        return Ok(dto);
    }

    [HttpPost]
    public async Task<IActionResult> CreateSituation([FromBody] SituationCreateDto dto)
    {
        var situation = new Situation
        {
            IslandId = dto.IslandId,
            Title = dto.Title,
            Intro = dto.Intro,
            OrderIndex = dto.OrderIndex,
            Status = "Draft", // Always start as Draft
            CreatedAt = DateTime.UtcNow
        };

        _context.Situations.Add(situation);
        await _context.SaveChangesAsync();

        if (dto.SkillIds != null && dto.SkillIds.Any())
        {
            foreach (var skillId in dto.SkillIds)
            {
                _context.SituationSkills.Add(new SituationSkill { SituationId = situation.SituationId, SkillId = skillId });
            }
            await _context.SaveChangesAsync();
        }

        return CreatedAtAction(nameof(GetSituation), new { id = situation.SituationId }, situation);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSituation(int id, [FromBody] SituationUpdateDto dto)
    {
        var situation = await _context.Situations.Include(s => s.SituationSkills).FirstOrDefaultAsync(s => s.SituationId == id);
        if (situation == null) return NotFound();

        situation.IslandId = dto.IslandId;
        situation.Title = dto.Title;
        situation.Intro = dto.Intro;
        situation.OrderIndex = dto.OrderIndex;
        situation.Status = dto.Status;
        situation.UpdatedAt = DateTime.UtcNow;

        _context.SituationSkills.RemoveRange(situation.SituationSkills);
        if (dto.SkillIds != null && dto.SkillIds.Any())
        {
            foreach (var skillId in dto.SkillIds)
            {
                _context.SituationSkills.Add(new SituationSkill { SituationId = situation.SituationId, SkillId = skillId });
            }
        }

        await _context.SaveChangesAsync();
        return Ok(new { Message = "Situation updated successfully." });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSituation(int id)
    {
        var situation = await _context.Situations
            .Include(s => s.UserProgresses)
            .Include(s => s.Flashcards).ThenInclude(f => f.UserAnswers)
            .FirstOrDefaultAsync(s => s.SituationId == id);

        if (situation == null) return NotFound();

        bool hasAnswers = situation.Flashcards.Any(f => f.UserAnswers.Any());
        bool hasProgress = situation.UserProgresses.Any();

        if (hasAnswers || hasProgress)
        {
            situation.Status = "Hidden";
            situation.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Situation has user data. It was set to Hidden instead of deleted." });
        }

        _context.Situations.Remove(situation);
        await _context.SaveChangesAsync();
        return Ok(new { Message = "Situation deleted successfully." });
    }

    // --- Steps Management ---
    
    [HttpPost("{id}/steps")]
    public async Task<IActionResult> CreateStep(int id, [FromBody] SituationStep step)
    {
        step.SituationId = id;
        _context.SituationSteps.Add(step);
        await _context.SaveChangesAsync();
        return Ok(step);
    }

    [HttpPut("steps/{stepId}")]
    public async Task<IActionResult> UpdateStep(int stepId, [FromBody] SituationStep dto)
    {
        var step = await _context.SituationSteps.FindAsync(stepId);
        if (step == null) return NotFound();

        step.StepType = dto.StepType;
        step.Content = dto.Content;
        step.MediaUrl = dto.MediaUrl;
        step.OrderIndex = dto.OrderIndex;

        await _context.SaveChangesAsync();
        return Ok(step);
    }

    [HttpDelete("steps/{stepId}")]
    public async Task<IActionResult> DeleteStep(int stepId)
    {
        var step = await _context.SituationSteps.FindAsync(stepId);
        if (step == null) return NotFound();

        _context.SituationSteps.Remove(step);
        await _context.SaveChangesAsync();
        return Ok(new { Message = "Step deleted." });
    }

    // --- Flashcard Management ---

    [HttpPost("{id}/flashcards")]
    public async Task<IActionResult> CreateFlashcard(int id, [FromBody] Flashcard fc)
    {
        fc.SituationId = id;
        _context.Flashcards.Add(fc);
        await _context.SaveChangesAsync();
        return Ok(fc);
    }

    [HttpPut("flashcards/{fcId}")]
    public async Task<IActionResult> UpdateFlashcard(int fcId, [FromBody] Flashcard dto)
    {
        var fc = await _context.Flashcards.FindAsync(fcId);
        if (fc == null) return NotFound();

        fc.Question = dto.Question;
        fc.QuestionVoiceUrl = dto.QuestionVoiceUrl;
        fc.OptionA = dto.OptionA;
        fc.OptionAVoiceUrl = dto.OptionAVoiceUrl;
        fc.OptionB = dto.OptionB;
        fc.OptionBVoiceUrl = dto.OptionBVoiceUrl;
        fc.CorrectAnswer = dto.CorrectAnswer;
        fc.CorrectFeedback = dto.CorrectFeedback;
        fc.WrongFeedback = dto.WrongFeedback;

        await _context.SaveChangesAsync();
        return Ok(fc);
    }

    [HttpDelete("flashcards/{fcId}")]
    public async Task<IActionResult> DeleteFlashcard(int fcId)
    {
        var fc = await _context.Flashcards.Include(f => f.UserAnswers).FirstOrDefaultAsync(f => f.FlashcardId == fcId);
        if (fc == null) return NotFound();

        if (fc.UserAnswers.Any())
        {
            return BadRequest(new { Message = "Cannot delete Flashcard because it has user answers." });
        }

        _context.Flashcards.Remove(fc);
        await _context.SaveChangesAsync();
        return Ok(new { Message = "Flashcard deleted." });
    }
}

public class SituationCreateDto
{
    public int IslandId { get; set; }
    public string Title { get; set; } = null!;
    public string? Intro { get; set; }
    public int OrderIndex { get; set; }
    public List<int>? SkillIds { get; set; }
}

public class SituationUpdateDto : SituationCreateDto
{
    public string Status { get; set; } = null!;
}
