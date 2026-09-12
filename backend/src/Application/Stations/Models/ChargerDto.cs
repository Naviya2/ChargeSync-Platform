using Domain.Enums;

namespace Application.Stations.Models;

public class ChargerDto
{
    public Guid Id { get; set; }
    public Guid StationId { get; set; }
    public string Identifier { get; set; } = null!;
    public string BayLabel { get; set; } = null!;
    public ConnectorType Connector { get; set; }
    public decimal PowerKw { get; set; }
    public decimal Tariff { get; set; }
    public ChargerStatus Status { get; set; }
    public List<MaintenanceWindowDto> MaintenanceWindows { get; set; } = new();
}

public class MaintenanceWindowDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string Reason { get; set; } = null!;
    public DateTimeOffset StartTime { get; set; }
    public DateTimeOffset EndTime { get; set; }
}

public class AddChargerRequest
{
    public string Identifier { get; set; } = null!;
    public string BayLabel { get; set; } = null!;
    public ConnectorType Connector { get; set; }
    public decimal PowerKw { get; set; }
    public decimal Tariff { get; set; }
}
