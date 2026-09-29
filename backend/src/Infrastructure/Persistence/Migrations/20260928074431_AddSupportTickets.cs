using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSupportTickets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SupportTickets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DriverId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssignedToUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    InvoiceId = table.Column<Guid>(type: "uuid", nullable: true),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Subject = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    Priority = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RequestedRefundAmount = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: true),
                    RefundStatus = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    RefundReviewedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    RefundReviewedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Version = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportTickets", x => x.Id);
                    table.CheckConstraint("CK_SupportTickets_Category", "\"Category\" IN ('Charging','Reservation','Payment','Refund','Technical','Membership','Other')");
                    table.CheckConstraint("CK_SupportTickets_Priority", "\"Priority\" IN ('Low','Medium','High','Urgent')");
                    table.CheckConstraint("CK_SupportTickets_RefundAmount", "\"RequestedRefundAmount\" IS NULL OR \"RequestedRefundAmount\" > 0");
                    table.CheckConstraint("CK_SupportTickets_RefundStatus", "\"RefundStatus\" IN ('NotRequested','PendingReview','Approved','Rejected','Cancelled')");
                    table.CheckConstraint("CK_SupportTickets_Status", "\"Status\" IN ('Open','InProgress','Resolved','Closed','Withdrawn')");
                    table.ForeignKey(
                        name: "FK_SupportTickets_PaymentInvoices_InvoiceId",
                        column: x => x.InvoiceId,
                        principalTable: "PaymentInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SupportTickets_Users_AssignedToUserId",
                        column: x => x.AssignedToUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SupportTickets_Users_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SupportTickets_Users_RefundReviewedBy",
                        column: x => x.RefundReviewedBy,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SupportMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TicketId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuthorId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuthorRole = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Body = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    IsSystem = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupportMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupportMessages_SupportTickets_TicketId",
                        column: x => x.TicketId,
                        principalTable: "SupportTickets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SupportMessages_Users_AuthorId",
                        column: x => x.AuthorId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_AuthorId",
                table: "SupportMessages",
                column: "AuthorId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportMessages_TicketId_CreatedAt",
                table: "SupportMessages",
                columns: new[] { "TicketId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_AssignedToUserId",
                table: "SupportTickets",
                column: "AssignedToUserId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_DriverId",
                table: "SupportTickets",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_InvoiceId",
                table: "SupportTickets",
                column: "InvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_RefundReviewedBy",
                table: "SupportTickets",
                column: "RefundReviewedBy");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_Status_Priority_UpdatedAt",
                table: "SupportTickets",
                columns: new[] { "Status", "Priority", "UpdatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SupportMessages");

            migrationBuilder.DropTable(
                name: "SupportTickets");
        }
    }
}
