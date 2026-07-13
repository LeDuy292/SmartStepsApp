using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/situations")]
public sealed class SituationsController : ControllerBase
{
    private readonly SmartStepsDbContext _dbContext;

    public SituationsController(SmartStepsDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SituationSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<SituationSummaryResponse>>> GetSituations(
        CancellationToken cancellationToken)
    {
        var situations = await _dbContext.Situations
            .AsNoTracking()
            .Where(item => item.Status == "Published" && item.Island.Status == "Active")
            .OrderBy(item => item.Island.OrderIndex)
            .ThenBy(item => item.OrderIndex)
            .Select(item => new SituationSummaryResponse
            {
                SituationId = item.SituationId,
                IslandId = item.IslandId,
                IslandName = item.Island.Name,
                Title = item.Title,
                Intro = item.Intro,
                OrderIndex = item.OrderIndex,
                Status = item.Status
            })
            .ToListAsync(cancellationToken);

        return Ok(situations);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(SituationDetailResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SituationDetailResponse>> GetSituation(
        int id,
        CancellationToken cancellationToken)
    {
        var situation = await _dbContext.Situations
            .AsNoTracking()
            .Where(item =>
                item.SituationId == id &&
                item.Status == "Published" &&
                item.Island.Status == "Active")
            .Select(item => new SituationDetailResponse
            {
                SituationId = item.SituationId,
                IslandId = item.IslandId,
                IslandName = item.Island.Name,
                Title = item.Title,
                Intro = item.Intro,
                OrderIndex = item.OrderIndex,
                Status = item.Status,
                Steps = item.SituationSteps
                    .OrderBy(step => step.OrderIndex)
                    .Select(step => new SituationStepResponse
                    {
                        StepId = step.StepId,
                        StepType = step.StepType,
                        OrderIndex = step.OrderIndex,
                        Content = step.Content,
                        MediaUrl = step.MediaUrl
                    })
                    .ToList(),
                Flashcard = item.Flashcards
                    .OrderBy(flashcard => flashcard.FlashcardId)
                    .Select(flashcard => new FlashcardResponse
                    {
                        FlashcardId = flashcard.FlashcardId,
                        Question = flashcard.Question,
                        OptionA = flashcard.OptionA,
                        OptionB = flashcard.OptionB,
                        QuestionVoiceUrl = flashcard.QuestionVoiceUrl,
                        OptionAVoiceUrl = flashcard.OptionAVoiceUrl,
                        OptionBVoiceUrl = flashcard.OptionBVoiceUrl,
                        CorrectAnswer = flashcard.CorrectAnswer,
                        CorrectFeedback = flashcard.CorrectFeedback,
                        WrongFeedback = flashcard.WrongFeedback
                    })
                    .FirstOrDefault(),
                Skills = item.SituationSkills
                    .OrderBy(situationSkill => situationSkill.Skill.Name)
                    .Select(situationSkill => new SkillResponse
                    {
                        SkillId = situationSkill.SkillId,
                        Name = situationSkill.Skill.Name,
                        Description = situationSkill.Skill.Description
                    })
                    .ToList(),
                ParentReview = item.ParentReviewQuestions
                    .OrderBy(parentReview => parentReview.QuestionId)
                    .Select(parentReview => new ParentReviewQuestionResponse
                    {
                        QuestionId = parentReview.QuestionId,
                        SkillId = parentReview.SkillId,
                        QuestionText = parentReview.QuestionText,
                        SuggestedActivity = parentReview.SuggestedActivity
                    })
                    .FirstOrDefault()
            })
            .SingleOrDefaultAsync(cancellationToken);

        if (situation is null)
        {
            return NotFound(new { message = "Situation was not found." });
        }

        return Ok(situation);
    }
}

public class SituationSummaryResponse
{
    public int SituationId { get; set; }

    public int IslandId { get; set; }

    public string IslandName { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string? Intro { get; set; }

    public int OrderIndex { get; set; }

    public string Status { get; set; } = string.Empty;
}

public sealed class SituationDetailResponse : SituationSummaryResponse
{
    public IReadOnlyList<SituationStepResponse> Steps { get; set; } = [];

    public FlashcardResponse? Flashcard { get; set; }

    public IReadOnlyList<SkillResponse> Skills { get; set; } = [];

    public ParentReviewQuestionResponse? ParentReview { get; set; }
}

public sealed class SituationStepResponse
{
    public int StepId { get; set; }

    public string StepType { get; set; } = string.Empty;

    public int OrderIndex { get; set; }

    public string? Content { get; set; }

    public string? MediaUrl { get; set; }
}

public sealed class FlashcardResponse
{
    public int FlashcardId { get; set; }

    public string Question { get; set; } = string.Empty;

    public string OptionA { get; set; } = string.Empty;

    public string OptionB { get; set; } = string.Empty;

    public string? QuestionVoiceUrl { get; set; }

    public string? OptionAVoiceUrl { get; set; }

    public string? OptionBVoiceUrl { get; set; }

    public string CorrectAnswer { get; set; } = string.Empty;

    public string? CorrectFeedback { get; set; }

    public string? WrongFeedback { get; set; }
}

public sealed class SkillResponse
{
    public int SkillId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }
}

public sealed class ParentReviewQuestionResponse
{
    public int QuestionId { get; set; }

    public int SkillId { get; set; }

    public string QuestionText { get; set; } = string.Empty;

    public string? SuggestedActivity { get; set; }
}
