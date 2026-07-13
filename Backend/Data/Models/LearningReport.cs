using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartStepsServer.Data.Models;

[Table("LearningReport")]
public class LearningReport
{
    [Key]
    public int ReportId { get; set; }

    public int ChildId { get; set; }

    public DateTime PeriodFrom { get; set; }

    public DateTime PeriodTo { get; set; }

    public int TotalLessons { get; set; }

    public int CompletedLessons { get; set; }

    public decimal CorrectRate { get; set; }

    public string Summary { get; set; } = string.Empty;

    public string Strengths { get; set; } = string.Empty;

    public string AreasForImprovement { get; set; } = string.Empty;

    public string ParentAdvice { get; set; } = string.Empty;

    public DateTime GeneratedAt { get; set; }

    [ForeignKey(nameof(ChildId))]
    public User Child { get; set; } = null!;

    public ICollection<AIAnalysisLog> AIAnalysisLogs { get; set; } = new List<AIAnalysisLog>();
}
