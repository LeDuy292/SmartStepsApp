using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartStepsServer.Migrations
{
    /// <inheritdoc />
    public partial class AddPremiumSubscriptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PremiumPayment",
                columns: table => new
                {
                    PaymentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    PlanCode = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false),
                    OrderCode = table.Column<long>(type: "bigint", nullable: false),
                    Amount = table.Column<int>(type: "int", nullable: false),
                    Currency = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    PaymentLinkId = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    CheckoutUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    QrCode = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ReturnUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    CancelUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    PaidAt = table.Column<DateTime>(type: "datetime", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PremiumPayment", x => x.PaymentId);
                    table.CheckConstraint("CK_PremiumPayment_Amount", "[Amount] >= 0");
                    table.CheckConstraint("CK_PremiumPayment_Status", "[Status] IN ('Pending', 'Paid', 'Cancelled', 'Expired', 'Failed')");
                    table.ForeignKey(
                        name: "FK_PremiumPayment_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "PremiumSubscription",
                columns: table => new
                {
                    SubscriptionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    PlanCode = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Source = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    PaymentId = table.Column<int>(type: "int", nullable: true),
                    StartedAt = table.Column<DateTime>(type: "datetime", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PremiumSubscription", x => x.SubscriptionId);
                    table.CheckConstraint("CK_PremiumSubscription_Source", "[Source] IN ('Payment', 'Code')");
                    table.CheckConstraint("CK_PremiumSubscription_Status", "[Status] IN ('Active', 'Expired', 'Cancelled')");
                    table.ForeignKey(
                        name: "FK_PremiumSubscription_PremiumPayment_PaymentId",
                        column: x => x.PaymentId,
                        principalTable: "PremiumPayment",
                        principalColumn: "PaymentId");
                    table.ForeignKey(
                        name: "FK_PremiumSubscription_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "PremiumCodeRedemption",
                columns: table => new
                {
                    RedemptionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    SubscriptionId = table.Column<int>(type: "int", nullable: false),
                    Code = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false),
                    RedeemedAt = table.Column<DateTime>(type: "datetime", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PremiumCodeRedemption", x => x.RedemptionId);
                    table.ForeignKey(
                        name: "FK_PremiumCodeRedemption_PremiumSubscription_SubscriptionId",
                        column: x => x.SubscriptionId,
                        principalTable: "PremiumSubscription",
                        principalColumn: "SubscriptionId");
                    table.ForeignKey(
                        name: "FK_PremiumCodeRedemption_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_PremiumCodeRedemption_SubscriptionId",
                table: "PremiumCodeRedemption",
                column: "SubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_PremiumCodeRedemption_UserId_Code",
                table: "PremiumCodeRedemption",
                columns: new[] { "UserId", "Code" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PremiumPayment_OrderCode",
                table: "PremiumPayment",
                column: "OrderCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PremiumPayment_PaymentLinkId",
                table: "PremiumPayment",
                column: "PaymentLinkId",
                unique: true,
                filter: "[PaymentLinkId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PremiumPayment_UserId",
                table: "PremiumPayment",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PremiumSubscription_PaymentId",
                table: "PremiumSubscription",
                column: "PaymentId");

            migrationBuilder.CreateIndex(
                name: "IX_PremiumSubscription_UserId_Status",
                table: "PremiumSubscription",
                columns: new[] { "UserId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PremiumCodeRedemption");

            migrationBuilder.DropTable(
                name: "PremiumSubscription");

            migrationBuilder.DropTable(
                name: "PremiumPayment");
        }
    }
}
