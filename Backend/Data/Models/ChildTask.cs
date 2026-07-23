using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("ChildTasks")]
public class ChildTask
{
    [Key]
    public int TaskId { get; set; }

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
    [StringLength(20)]
    public string Frequency { get; set; } = "Daily"; // Daily, Weekly, Once

    public DateTime? DueDate { get; set; }

    [Required]
    [StringLength(20)]
    public string Status { get; set; } = "Active"; // Active, Archived

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    [ForeignKey(nameof(ParentId))]
    public User? Parent { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User? Child { get; set; }

    public ICollection<TaskProgress> TaskProgresses { get; set; } = new List<TaskProgress>();
}
