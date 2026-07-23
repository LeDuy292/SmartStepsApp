using System.ComponentModel.DataAnnotations;

namespace SmartStepsServer.Data.DTOs;

public class CreateTaskDto
{
    [Required]
    public int ParentId { get; set; }

    public int? ChildId { get; set; }

    [Required]
    [StringLength(150)]
    public string Title { get; set; } = null!;

    [StringLength(500)]
    public string? Description { get; set; }

    public int RewardPoints { get; set; } = 10;

    [Required]
    public string Frequency { get; set; } = "Daily";

    public DateTime? DueDate { get; set; }
}

public class CompleteTaskDto
{
    [Required]
    public int ChildId { get; set; }

    public string? ProofImageUrl { get; set; }

    public string? Note { get; set; }
}

public class TaskResponseDto
{
    public int TaskId { get; set; }
    public int ParentId { get; set; }
    public int? ChildId { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public int RewardPoints { get; set; }
    public string Frequency { get; set; } = null!;
    public DateTime? DueDate { get; set; }
    public string Status { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
    public TaskProgressDto? LatestProgress { get; set; }
}

public class TaskProgressDto
{
    public int TaskProgressId { get; set; }
    public int TaskId { get; set; }
    public int ChildId { get; set; }
    public string Status { get; set; } = null!;
    public string? ProofImageUrl { get; set; }
    public string? Note { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? ApprovedAt { get; set; }
}
