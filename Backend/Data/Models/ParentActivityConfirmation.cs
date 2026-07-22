using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("ParentActivityConfirmation")]
public sealed class ParentActivityConfirmation
{
    [Key]
    public int ConfirmationId { get; set; }
    public int ParentId { get; set; }
    public int ChildId { get; set; }
    public int SituationId { get; set; }
    [MaxLength(1000)]
    public string Note { get; set; } = string.Empty;
    public DateTime ConfirmedAt { get; set; }

    [ForeignKey(nameof(ParentId))]
    public User Parent { get; set; } = null!;
    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;
    [ForeignKey(nameof(SituationId))]
    public Situation Situation { get; set; } = null!;
}
