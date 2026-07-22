using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace SmartStepsServer.Migrations
{
    /// <inheritdoc />
    public partial class AddFamilyPremiumFeedbackWorkflows : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_PremiumPayment_Status",
                table: "PremiumPayment");

            migrationBuilder.AddColumn<string>(
                name: "AdminResponse",
                table: "AppFeedback",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "AppFeedback",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "ResolvedAt",
                table: "AppFeedback",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SituationId",
                table: "AppFeedback",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "AppFeedback",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "AppFeedback",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ChildLinkCode",
                columns: table => new
                {
                    ChildLinkCodeId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    Code = table.Column<string>(type: "character varying(12)", maxLength: 12, nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UsedByParentId = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildLinkCode", x => x.ChildLinkCodeId);
                    table.ForeignKey(
                        name: "FK_ChildLinkCode_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                    table.ForeignKey(
                        name: "FK_ChildLinkCode_Users_UsedByParentId",
                        column: x => x.UsedByParentId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "LessonAssignment",
                columns: table => new
                {
                    AssignmentId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ParentId = table.Column<int>(type: "integer", nullable: false),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    SituationId = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DueAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonAssignment", x => x.AssignmentId);
                    table.CheckConstraint("CK_LessonAssignment_Status", "\"Status\" IN ('Assigned', 'InProgress', 'Completed', 'Cancelled')");
                    table.ForeignKey(
                        name: "FK_LessonAssignment_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_LessonAssignment_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                    table.ForeignKey(
                        name: "FK_LessonAssignment_Users_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "ParentActivityConfirmation",
                columns: table => new
                {
                    ConfirmationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ParentId = table.Column<int>(type: "integer", nullable: false),
                    ChildId = table.Column<int>(type: "integer", nullable: false),
                    SituationId = table.Column<int>(type: "integer", nullable: false),
                    Note = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ConfirmedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParentActivityConfirmation", x => x.ConfirmationId);
                    table.ForeignKey(
                        name: "FK_ParentActivityConfirmation_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_ParentActivityConfirmation_Users_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                    table.ForeignKey(
                        name: "FK_ParentActivityConfirmation_Users_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.AddCheckConstraint(
                name: "CK_PremiumPayment_Status",
                table: "PremiumPayment",
                sql: "\"Status\" IN ('Pending', 'Paid', 'Cancelled', 'Expired', 'Failed', 'Refunded')");

            migrationBuilder.CreateIndex(
                name: "IX_AppFeedback_SituationId",
                table: "AppFeedback",
                column: "SituationId");

            migrationBuilder.AddCheckConstraint(
                name: "CK_AppFeedback_Category",
                table: "AppFeedback",
                sql: "\"Category\" IN ('Bug', 'Suggestion', 'InappropriateContent')");

            migrationBuilder.AddCheckConstraint(
                name: "CK_AppFeedback_Status",
                table: "AppFeedback",
                sql: "\"Status\" IN ('New', 'Processing', 'Resolved')");

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkCode_ChildId",
                table: "ChildLinkCode",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkCode_Code",
                table: "ChildLinkCode",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkCode_UsedByParentId",
                table: "ChildLinkCode",
                column: "UsedByParentId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonAssignment_ChildId_Status",
                table: "LessonAssignment",
                columns: new[] { "ChildId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonAssignment_ParentId",
                table: "LessonAssignment",
                column: "ParentId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonAssignment_SituationId",
                table: "LessonAssignment",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentActivityConfirmation_ChildId",
                table: "ParentActivityConfirmation",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentActivityConfirmation_ParentId_ChildId_SituationId",
                table: "ParentActivityConfirmation",
                columns: new[] { "ParentId", "ChildId", "SituationId" });

            migrationBuilder.CreateIndex(
                name: "IX_ParentActivityConfirmation_SituationId",
                table: "ParentActivityConfirmation",
                column: "SituationId");

            migrationBuilder.AddForeignKey(
                name: "FK_AppFeedback_Situation_SituationId",
                table: "AppFeedback",
                column: "SituationId",
                principalTable: "Situation",
                principalColumn: "SituationId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AppFeedback_Situation_SituationId",
                table: "AppFeedback");

            migrationBuilder.DropTable(
                name: "ChildLinkCode");

            migrationBuilder.DropTable(
                name: "LessonAssignment");

            migrationBuilder.DropTable(
                name: "ParentActivityConfirmation");

            migrationBuilder.DropCheckConstraint(
                name: "CK_PremiumPayment_Status",
                table: "PremiumPayment");

            migrationBuilder.DropIndex(
                name: "IX_AppFeedback_SituationId",
                table: "AppFeedback");

            migrationBuilder.DropCheckConstraint(
                name: "CK_AppFeedback_Category",
                table: "AppFeedback");

            migrationBuilder.DropCheckConstraint(
                name: "CK_AppFeedback_Status",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "AdminResponse",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "ResolvedAt",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "SituationId",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "AppFeedback");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "AppFeedback");

            migrationBuilder.AddCheckConstraint(
                name: "CK_PremiumPayment_Status",
                table: "PremiumPayment",
                sql: "\"Status\" IN ('Pending', 'Paid', 'Cancelled', 'Expired', 'Failed')");
        }
    }
}
