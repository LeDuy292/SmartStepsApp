using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("PremiumPayment")]
public class PremiumPayment
{
    [Key]
    public int PaymentId { get; set; }

    public int UserId { get; set; }

    [Required]
    [StringLength(50)]
    [Column(TypeName = "varchar(50)")]
    public string PlanCode { get; set; } = null!;

    public long OrderCode { get; set; }

    public int Amount { get; set; }

    [Required]
    [StringLength(10)]
    [Column(TypeName = "varchar(10)")]
    public string Currency { get; set; } = "VND";

    [Required]
    [StringLength(100)]
    public string Description { get; set; } = null!;

    [Required]
    [StringLength(30)]
    [Column(TypeName = "varchar(30)")]
    public string Status { get; set; } = null!;

    [StringLength(100)]
    [Column(TypeName = "varchar(100)")]
    public string? PaymentLinkId { get; set; }

    [StringLength(500)]
    [Column(TypeName = "varchar(500)")]
    public string? CheckoutUrl { get; set; }

    public string? QrCode { get; set; }

    [StringLength(500)]
    [Column(TypeName = "varchar(500)")]
    public string? ReturnUrl { get; set; }

    [StringLength(500)]
    [Column(TypeName = "varchar(500)")]
    public string? CancelUrl { get; set; }

    public DateTime? PaidAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    public ICollection<PremiumSubscription> PremiumSubscriptions { get; set; } =
        new List<PremiumSubscription>();
}
