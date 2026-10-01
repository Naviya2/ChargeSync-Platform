using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddWalkInDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WaitlistEntries");

            migrationBuilder.AddColumn<double>(
                name: "WalkInBatteryCapacity",
                table: "Reservations",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "WalkInCustomerName",
                table: "Reservations",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "WalkInVehicleNumber",
                table: "Reservations",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_VehicleId",
                table: "Reservations",
                column: "VehicleId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_Chargers_ChargerId",
                table: "Reservations",
                column: "ChargerId",
                principalTable: "Chargers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_Vehicles_VehicleId",
                table: "Reservations",
                column: "VehicleId",
                principalTable: "Vehicles",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_Chargers_ChargerId",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_Vehicles_VehicleId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_VehicleId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "WalkInBatteryCapacity",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "WalkInCustomerName",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "WalkInVehicleNumber",
                table: "Reservations");

            migrationBuilder.CreateTable(
                name: "WaitlistEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    DriverId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChargerId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    Priority = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    RequestedStartTime = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "Waiting"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaitlistEntries", x => x.Id);
                    table.CheckConstraint("CK_WaitlistEntries_Status", "\"Status\" IN ('Waiting', 'Promoted', 'Expired')");
                    table.ForeignKey(
                        name: "FK_WaitlistEntries_Users_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WaitlistEntries_ChargerId_Status_Priority",
                table: "WaitlistEntries",
                columns: new[] { "ChargerId", "Status", "Priority" });

            migrationBuilder.CreateIndex(
                name: "IX_WaitlistEntries_DriverId",
                table: "WaitlistEntries",
                column: "DriverId");
        }
    }
}
