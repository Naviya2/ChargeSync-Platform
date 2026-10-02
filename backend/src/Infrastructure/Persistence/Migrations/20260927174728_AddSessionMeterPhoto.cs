using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSessionMeterPhoto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "MeterPhoto",
                table: "ChargingSessions",
                type: "bytea",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MeterPhotoContentType",
                table: "ChargingSessions",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MeterPhoto",
                table: "ChargingSessions");

            migrationBuilder.DropColumn(
                name: "MeterPhotoContentType",
                table: "ChargingSessions");
        }
    }
}
