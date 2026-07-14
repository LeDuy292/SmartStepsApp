using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace SmartStepsServer.Migrations
{
    /// <inheritdoc />
    public partial class AddProfileAndFeedback : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ProfileJson",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AppFeedback",
                columns: table => new
                {
                    FeedbackId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    ClientId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Source = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ExperienceRating = table.Column<int>(type: "integer", nullable: false),
                    ChildEngagementRating = table.Column<int>(type: "integer", nullable: false),
                    EffectivenessRating = table.Column<int>(type: "integer", nullable: false),
                    AgeFit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ImprovementNote = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    SubmittedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppFeedback", x => x.FeedbackId);
                    table.CheckConstraint("CK_AppFeedback_ChildEngagementRating", "\"ChildEngagementRating\" BETWEEN 1 AND 5");
                    table.CheckConstraint("CK_AppFeedback_EffectivenessRating", "\"EffectivenessRating\" BETWEEN 1 AND 5");
                    table.CheckConstraint("CK_AppFeedback_ExperienceRating", "\"ExperienceRating\" BETWEEN 1 AND 5");
                    table.ForeignKey(
                        name: "FK_AppFeedback_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_AppFeedback_UserId_ClientId",
                table: "AppFeedback",
                columns: new[] { "UserId", "ClientId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "ProfileJson",
                table: "Users");
        }
    }
}
