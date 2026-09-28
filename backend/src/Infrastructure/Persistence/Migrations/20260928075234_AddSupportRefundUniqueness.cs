using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSupportRefundUniqueness : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SupportTickets_InvoiceId",
                table: "SupportTickets");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_InvoiceId",
                table: "SupportTickets",
                column: "InvoiceId",
                unique: true,
                filter: "\"InvoiceId\" IS NOT NULL AND \"RefundStatus\" IN ('PendingReview','Approved')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SupportTickets_InvoiceId",
                table: "SupportTickets");

            migrationBuilder.CreateIndex(
                name: "IX_SupportTickets_InvoiceId",
                table: "SupportTickets",
                column: "InvoiceId");
        }
    }
}
