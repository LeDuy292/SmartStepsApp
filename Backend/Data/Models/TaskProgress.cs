using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("TaskProgresses")]
public class TaskProgress
{
    [Key]
    public int TaskProgressId { get; set; }

    [Required]
    public int TaskId { get; set; }

    [Required]
    public int ChildId { get; set; }

    [Required]
    [StringLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Completed, Approved, Rejected

    [StringLength(500)]
    public string? ProofImageUrl { get; set; }

    [StringLength(255)]
    public string? Note { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime? ApprovedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey(nameof(TaskId))]
    public ChildTask? Task { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User? Child { get; set; }
}
