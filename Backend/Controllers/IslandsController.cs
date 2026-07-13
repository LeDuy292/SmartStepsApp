using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;

namespace SmartStepsServer.Controllers;

[ApiController]
[Route("api/islands")]
public sealed class IslandsController : ControllerBase
{
    private readonly SmartStepsDbContext _dbContext;

    public IslandsController(SmartStepsDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<IslandSummaryResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<IslandSummaryResponse>>> GetIslands(
        CancellationToken cancellationToken)
    {
        var islands = await _dbContext.Islands
            .AsNoTracking()
            .Where(island => island.Status == "Active")
            .OrderBy(island => island.OrderIndex)
            .Select(island => new IslandSummaryResponse
            {
                IslandId = island.IslandId,
                Name = island.Name,
                Description = island.Description,
                ImageUrl = island.ImageUrl,
                OrderIndex = island.OrderIndex,
                Status = island.Status,
                SituationCount = island.Situations.Count(situation => situation.Status == "Published")
            })
            .ToListAsync(cancellationToken);

        return Ok(islands);
    }

    [HttpGet("{id:int}/situations")]
    [ProducesResponseType(typeof(IReadOnlyList<SituationSummaryResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<SituationSummaryResponse>>> GetIslandSituations(
        int id,
        CancellationToken cancellationToken)
    {
        var islandExists = await _dbContext.Islands
            .AsNoTracking()
            .AnyAsync(island => island.IslandId == id && island.Status == "Active", cancellationToken);

        if (!islandExists)
        {
            return NotFound(new { message = "Island was not found." });
        }

        var situations = await _dbContext.Situations
            .AsNoTracking()
            .Where(situation =>
                situation.IslandId == id &&
                situation.Status == "Published" &&
                situation.Island.Status == "Active")
            .OrderBy(situation => situation.OrderIndex)
            .Select(situation => new SituationSummaryResponse
            {
                SituationId = situation.SituationId,
                IslandId = situation.IslandId,
                IslandName = situation.Island.Name,
                Title = situation.Title,
                Intro = situation.Intro,
                OrderIndex = situation.OrderIndex,
                Status = situation.Status
            })
            .ToListAsync(cancellationToken);

        return Ok(situations);
    }
}

public sealed class IslandSummaryResponse
{
    public int IslandId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string? ImageUrl { get; set; }

    public int OrderIndex { get; set; }

    public string Status { get; set; } = string.Empty;

    public int SituationCount { get; set; }
}
