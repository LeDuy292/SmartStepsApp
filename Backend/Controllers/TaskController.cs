using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStepsServer.Data;
using SmartStepsServer.Data.DTOs;
using SmartStepsServer.Data.Models;

namespace SmartStepsServer.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/tasks")]
public sealed class TaskController(SmartStepsDbContext dbContext) : ControllerBase
{
    [HttpGet("child/{childId:int}")]
    public async Task<IActionResult> GetChildTasks(int childId, CancellationToken cancellationToken)
    {
        var tasks = await dbContext.ChildTasks
            .AsNoTracking()
            .Where(t => t.ChildId == childId || t.ChildId == null || t.ChildId <= 0 || childId <= 0)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new TaskResponseDto
            {
                TaskId = t.TaskId,
                ParentId = t.ParentId,
                ChildId = t.ChildId,
                Title = t.Title,
                Description = t.Description,
                RewardPoints = t.RewardPoints,
                Frequency = t.Frequency,
                DueDate = t.DueDate,
                Status = t.Status,
                CreatedAt = t.CreatedAt,
                LatestProgress = dbContext.TaskProgresses
                    .Where(p => p.TaskId == t.TaskId)
                    .OrderByDescending(p => p.CreatedAt)
                    .Select(p => new TaskProgressDto
                    {
                        TaskProgressId = p.TaskProgressId,
                        TaskId = p.TaskId,
                        ChildId = p.ChildId,
                        Status = p.Status,
                        ProofImageUrl = p.ProofImageUrl,
                        Note = p.Note,
                        CompletedAt = p.CompletedAt,
                        ApprovedAt = p.ApprovedAt
                    }).FirstOrDefault()
            })
            .ToListAsync(cancellationToken);

        return Ok(tasks);
    }

    [HttpGet]
    public async Task<IActionResult> GetAllTasks(CancellationToken cancellationToken)
    {
        return await GetChildTasks(0, cancellationToken);
    }

    [HttpPost]
    public async Task<IActionResult> CreateTask([FromBody] CreateTaskDto dto, CancellationToken cancellationToken)
    {
        int parentId = dto.ParentId;
        if (parentId <= 0 && TryGetUserId(out var claimUserId))
        {
            parentId = claimUserId;
        }

        if (parentId <= 0 || !await dbContext.Users.AnyAsync(u => u.UserId == parentId, cancellationToken))
        {
            var fallbackUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Role == "Parent" || u.Role == "Admin", cancellationToken)
                              ?? await dbContext.Users.FirstOrDefaultAsync(cancellationToken);
            if (fallbackUser != null)
            {
                parentId = fallbackUser.UserId;
            }
            else
            {
                return BadRequest(new { message = "Không tìm thấy người dùng phụ huynh hợp lệ trong hệ thống." });
            }
        }

        int? childId = dto.ChildId;

        var task = new ChildTask
        {
            ParentId = parentId,
            ChildId = childId,
            Title = dto.Title,
            Description = dto.Description,
            RewardPoints = dto.RewardPoints,
            Frequency = string.IsNullOrWhiteSpace(dto.Frequency) ? "Daily" : dto.Frequency,
            DueDate = dto.DueDate,
            Status = "Active",
            CreatedAt = DateTime.UtcNow
        };

        dbContext.ChildTasks.Add(task);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new TaskResponseDto
        {
            TaskId = task.TaskId,
            ParentId = task.ParentId,
            ChildId = task.ChildId,
            Title = task.Title,
            Description = task.Description,
            RewardPoints = task.RewardPoints,
            Frequency = task.Frequency,
            DueDate = task.DueDate,
            Status = task.Status,
            CreatedAt = task.CreatedAt
        });
    }

    private bool TryGetUserId(out int userId) => int.TryParse(
        User.FindFirstValue("UserId") ?? User.FindFirstValue(ClaimTypes.NameIdentifier), out userId);

    [HttpPost("{taskId:int}/complete")]
    public async Task<IActionResult> CompleteTask(int taskId, [FromBody] CompleteTaskDto dto, CancellationToken cancellationToken)
    {
        var task = await dbContext.ChildTasks.FindAsync([taskId], cancellationToken);
        if (task == null) return NotFound("Không tìm thấy nhiệm vụ");

        var progress = new TaskProgress
        {
            TaskId = taskId,
            ChildId = dto.ChildId,
            Status = "Completed",
            ProofImageUrl = dto.ProofImageUrl,
            Note = dto.Note,
            CompletedAt = DateTime.UtcNow
        };

        dbContext.TaskProgresses.Add(progress);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new TaskProgressDto
        {
            TaskProgressId = progress.TaskProgressId,
            TaskId = progress.TaskId,
            ChildId = progress.ChildId,
            Status = progress.Status,
            ProofImageUrl = progress.ProofImageUrl,
            Note = progress.Note,
            CompletedAt = progress.CompletedAt
        });
    }

    [HttpPost("progress/{progressId:int}/approve")]
    public async Task<IActionResult> ApproveTask(int progressId, CancellationToken cancellationToken)
    {
        var progress = await dbContext.TaskProgresses
            .Include(p => p.Task)
            .FirstOrDefaultAsync(p => p.TaskProgressId == progressId, cancellationToken);

        if (progress == null) return NotFound("Không tìm thấy tiến độ nhiệm vụ");

        progress.Status = "Approved";
        progress.ApprovedAt = DateTime.UtcNow;

        if (progress.Task != null)
        {
            progress.Task.Status = "Approved";
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new { Message = "Đã duyệt hoàn thành nhiệm vụ và cộng điểm cho bé!" });
    }

    [HttpPost("{taskId:int}/approve")]
    public async Task<IActionResult> ApproveTaskDirect(int taskId, CancellationToken cancellationToken)
    {
        var task = await dbContext.ChildTasks.FindAsync([taskId], cancellationToken);
        if (task == null) return NotFound("Không tìm thấy nhiệm vụ");

        task.Status = "Approved";

        var progress = await dbContext.TaskProgresses
            .FirstOrDefaultAsync(p => p.TaskId == taskId, cancellationToken);
        if (progress == null)
        {
            progress = new TaskProgress
            {
                TaskId = taskId,
                ChildId = task.ChildId ?? 1,
                Status = "Approved",
                ApprovedAt = DateTime.UtcNow,
                CompletedAt = DateTime.UtcNow
            };
            dbContext.TaskProgresses.Add(progress);
        }
        else
        {
            progress.Status = "Approved";
            progress.ApprovedAt = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { Message = "Đã duyệt hoàn thành nhiệm vụ và cộng điểm cho bé!", RewardPoints = task.RewardPoints });
    }

    [HttpPut("{taskId:int}")]
    public async Task<IActionResult> UpdateTask(int taskId, [FromBody] CreateTaskDto dto, CancellationToken cancellationToken)
    {
        var task = await dbContext.ChildTasks.FindAsync([taskId], cancellationToken);
        if (task == null) return NotFound("Không tìm thấy nhiệm vụ");

        task.Title = dto.Title;
        task.Description = dto.Description;
        task.RewardPoints = dto.RewardPoints;
        if (!string.IsNullOrEmpty(dto.Frequency)) task.Frequency = dto.Frequency;

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(task);
    }

    [HttpDelete("{taskId:int}")]
    public async Task<IActionResult> DeleteTask(int taskId, CancellationToken cancellationToken)
    {
        var task = await dbContext.ChildTasks.FindAsync([taskId], cancellationToken);
        if (task == null) return NotFound("Không tìm thấy nhiệm vụ");

        dbContext.ChildTasks.Remove(task);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { Message = "Đã xóa nhiệm vụ thành công" });
    }
}
