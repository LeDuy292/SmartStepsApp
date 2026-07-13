using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace SmartStepsServer.Migrations
{
    /// <inheritdoc />
    public partial class AddLearningAnalysis : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LearningReport",
                columns: table => new
                {
                    ReportId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    PeriodFrom = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PeriodTo = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TotalLessons = table.Column<int>(type: "integer", nullable: false),
                    CompletedLessons = table.Column<int>(type: "integer", nullable: false),
                    CorrectRate = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    Summary = table.Column<string>(type: "text", nullable: false),
                    Strengths = table.Column<string>(type: "text", nullable: false),
                    AreasForImprovement = table.Column<string>(type: "text", nullable: false),
                    ParentAdvice = table.Column<string>(type: "text", nullable: false),
                    GeneratedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LearningReport", x => x.ReportId);
                    table.CheckConstraint("CK_LearningReport_CorrectRate", "\"CorrectRate\" >= 0 AND \"CorrectRate\" <= 1");
                    table.CheckConstraint("CK_LearningReport_Period", "\"PeriodTo\" >= \"PeriodFrom\"");
                    table.ForeignKey(
                        name: "FK_LearningReport_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "LessonRecommendation",
                columns: table => new
                {
                    RecommendationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    SituationId = table.Column<int>(type: "integer", nullable: false),
                    RecommendationType = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonRecommendation", x => x.RecommendationId);
                    table.CheckConstraint("CK_LessonRecommendation_Priority", "\"Priority\" >= 0 AND \"Priority\" <= 100");
                    table.CheckConstraint("CK_LessonRecommendation_Status", "\"Status\" IN ('Pending', 'Completed', 'Dismissed')");
                    table.CheckConstraint("CK_LessonRecommendation_Type", "\"RecommendationType\" IN ('NextLesson', 'Review', 'WeakSkill', 'PeriodicReview')");
                    table.ForeignKey(
                        name: "FK_LessonRecommendation_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_LessonRecommendation_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "SkillAssessment",
                columns: table => new
                {
                    AssessmentId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    SkillId = table.Column<int>(type: "integer", nullable: false),
                    TotalAttempts = table.Column<int>(type: "integer", nullable: false),
                    CorrectAttempts = table.Column<int>(type: "integer", nullable: false),
                    CorrectRate = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    MasteryLevel = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    LastAssessedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SkillAssessment", x => x.AssessmentId);
                    table.CheckConstraint("CK_SkillAssessment_CorrectRate", "\"CorrectRate\" >= 0 AND \"CorrectRate\" <= 1");
                    table.CheckConstraint("CK_SkillAssessment_MasteryLevel", "\"MasteryLevel\" IN ('NotAchieved', 'NeedsReview', 'Achieved', 'Mastered')");
                    table.ForeignKey(
                        name: "FK_SkillAssessment_Skill_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skill",
                        principalColumn: "SkillId");
                    table.ForeignKey(
                        name: "FK_SkillAssessment_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "AIAnalysisLog",
                columns: table => new
                {
                    AnalysisId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    ReportId = table.Column<int>(type: "integer", nullable: true),
                    RequestData = table.Column<string>(type: "jsonb", nullable: false),
                    ResponseData = table.Column<string>(type: "jsonb", nullable: true),
                    ModelName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    ErrorMessage = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AIAnalysisLog", x => x.AnalysisId);
                    table.CheckConstraint("CK_AIAnalysisLog_Status", "\"Status\" IN ('Succeeded', 'Fallback', 'Failed', 'Skipped')");
                    table.ForeignKey(
                        name: "FK_AIAnalysisLog_LearningReport_ReportId",
                        column: x => x.ReportId,
                        principalTable: "LearningReport",
                        principalColumn: "ReportId");
                    table.ForeignKey(
                        name: "FK_AIAnalysisLog_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_AIAnalysisLog_ChildId_CreatedAt",
                table: "AIAnalysisLog",
                columns: new[] { "ChildId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_AIAnalysisLog_ReportId",
                table: "AIAnalysisLog",
                column: "ReportId");

            migrationBuilder.CreateIndex(
                name: "IX_LearningReport_ChildId_PeriodFrom_PeriodTo",
                table: "LearningReport",
                columns: new[] { "ChildId", "PeriodFrom", "PeriodTo" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonRecommendation_ChildId_Status_Priority",
                table: "LessonRecommendation",
                columns: new[] { "ChildId", "Status", "Priority" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonRecommendation_SituationId",
                table: "LessonRecommendation",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_SkillAssessment_ChildId_SkillId",
                table: "SkillAssessment",
                columns: new[] { "ChildId", "SkillId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SkillAssessment_SkillId",
                table: "SkillAssessment",
                column: "SkillId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AIAnalysisLog");

            migrationBuilder.DropTable(
                name: "LessonRecommendation");

            migrationBuilder.DropTable(
                name: "SkillAssessment");

            migrationBuilder.DropTable(
                name: "LearningReport");
        }
    }
}
