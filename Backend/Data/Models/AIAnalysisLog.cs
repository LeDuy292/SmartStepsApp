using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("AIAnalysisLog")]
public class AIAnalysisLog
{
    [Key]
    public int AnalysisId { get; set; }

    public int ChildId { get; set; }

    public int? ReportId { get; set; }

    public string RequestData { get; set; } = string.Empty;

    public string? ResponseData { get; set; }

    [StringLength(100)]
    public string ModelName { get; set; } = "RuleBasedFallback";

    [StringLength(30)]
    public string Status { get; set; } = null!;

    public string? ErrorMessage { get; set; }

    public DateTime CreatedAt { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;

    [ForeignKey(nameof(ReportId))]
    public LearningReport? Report { get; set; }
}
