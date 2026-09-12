using Domain.Enums;

namespace Application.Stations.Models;

public class StationDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Address { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public StationStatus Status { get; set; }
    public string? RejectionReason { get; set; }
    public Guid OwnerId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    
    public List<ChargerDto> Chargers { get; set; } = new();
    public List<OperatingHourDto> OperatingHours { get; set; } = new();
}

public class OperatingHourDto
{
    public Guid Id { get; set; }
    public int DayOfWeek { get; set; }
    public bool IsEnabled { get; set; }
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }
}

public class RegisterStationRequest
{
    public string Name { get; set; } = null!;
    public string Address { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}
