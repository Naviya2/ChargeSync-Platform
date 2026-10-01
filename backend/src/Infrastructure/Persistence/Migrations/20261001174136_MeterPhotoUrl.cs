using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MeterPhotoUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MeterPhoto",
                table: "ChargingSessions");

            migrationBuilder.RenameColumn(
                name: "MeterPhotoContentType",
                table: "ChargingSessions",
                newName: "MeterPhotoUrl");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "MeterPhotoUrl",
                table: "ChargingSessions",
                newName: "MeterPhotoContentType");

            migrationBuilder.AddColumn<byte[]>(
                name: "MeterPhoto",
                table: "ChargingSessions",
                type: "bytea",
                nullable: true);
        }
    }
}
