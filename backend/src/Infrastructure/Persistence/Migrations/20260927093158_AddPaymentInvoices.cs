using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentInvoices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PaymentInvoices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    SessionId = table.Column<Guid>(type: "uuid", nullable: false),
                    DriverId = table.Column<Guid>(type: "uuid", nullable: true),
                    GrossAmount = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    AdvanceDeducted = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    NetAmountDue = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    PaymentMethod = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "Pending"),
                    IssuedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    SettledAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentInvoices", x => x.Id);
                    table.CheckConstraint("CK_PaymentInvoices_Amounts", "\"GrossAmount\" >= 0 AND \"AdvanceDeducted\" >= 0 AND \"NetAmountDue\" >= 0");
                    table.CheckConstraint("CK_PaymentInvoices_PaymentMethod", "\"PaymentMethod\" IS NULL OR \"PaymentMethod\" IN ('Wallet', 'Cash')");
                    table.CheckConstraint("CK_PaymentInvoices_Status", "\"Status\" IN ('Pending', 'Paid', 'Refunded')");
                    table.ForeignKey(
                        name: "FK_PaymentInvoices_ChargingSessions_SessionId",
                        column: x => x.SessionId,
                        principalTable: "ChargingSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PaymentInvoices_Users_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PaymentInvoices_DriverId",
                table: "PaymentInvoices",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentInvoices_SessionId",
                table: "PaymentInvoices",
                column: "SessionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PaymentInvoices_Status",
                table: "PaymentInvoices",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PaymentInvoices");
        }
    }
}
