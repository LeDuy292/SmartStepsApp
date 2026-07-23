using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("ChildLinkCode")]
public sealed class ChildLinkCode
{
    [Key]
    public int ChildLinkCodeId { get; set; }
    public int ChildId { get; set; }
    [Required, MaxLength(12)]
    public string Code { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public int? UsedByParentId { get; set; }
    public DateTime CreatedAt { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;
    [ForeignKey(nameof(UsedByParentId))]
    public User? UsedByParent { get; set; }
}
