using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("Island")]
public class Island
{
    [Key]
    public int IslandId { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = null!;

    [StringLength(500)]
    public string? Description { get; set; }

    [StringLength(500)]
    [Column(TypeName = "varchar(500)")]
    public string? ImageUrl { get; set; }

    public int OrderIndex { get; set; }

    [Required]
    [StringLength(30)]
    [RegularExpression("^(Active|Hidden)$")]
    [Column(TypeName = "varchar(30)")]
    public string Status { get; set; } = null!; // Active, Hidden

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<Situation> Situations { get; set; } = new List<Situation>();
    public ICollection<UserProgress> UserProgresses { get; set; } = new List<UserProgress>();
}
