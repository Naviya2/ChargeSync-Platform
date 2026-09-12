using Domain.Common;
using Domain.Enums;

namespace Domain.Entities;

public class Charger : AuditableEntity
{
    private Charger() { }

    private Charger(Guid stationId, string identifier, string bayLabel, ConnectorType connector, decimal powerKw, decimal tariff, ChargerStatus status)
    {
        StationId = stationId;
        Identifier = identifier;
        BayLabel = bayLabel;
        Connector = connector;
        PowerKw = powerKw;
        Tariff = tariff;
        Status = status;
        MaintenanceWindows = new List<MaintenanceWindow>();
    }

    public Guid Id { get; private set; }
    public Guid StationId { get; private set; }
    
    public string Identifier { get; private set; } = null!;
    public string BayLabel { get; private set; } = null!;
    
    public ConnectorType Connector { get; private set; }
    public decimal PowerKw { get; private set; }
    public decimal Tariff { get; private set; }
    public ChargerStatus Status { get; private set; }

    public Station Station { get; private set; } = null!;
    public ICollection<MaintenanceWindow> MaintenanceWindows { get; private set; } = null!;

    public static Charger Create(Guid stationId, string identifier, string bayLabel, ConnectorType connector, decimal powerKw, decimal tariff, ChargerStatus status = ChargerStatus.Available)
    {
        if (string.IsNullOrWhiteSpace(identifier))
            throw new ArgumentException("Identifier is required.", nameof(identifier));
        
        if (powerKw <= 0)
            throw new ArgumentException("Power output must be positive.", nameof(powerKw));

        if (tariff < 0)
            throw new ArgumentException("Tariff cannot be negative.", nameof(tariff));

        return new Charger(stationId, identifier.Trim(), bayLabel?.Trim() ?? string.Empty, connector, powerKw, tariff, status);
    }

    public void UpdateDetails(string identifier, string bayLabel, ConnectorType connector, decimal powerKw, decimal tariff)
    {
        if (string.IsNullOrWhiteSpace(identifier))
            throw new ArgumentException("Identifier is required.", nameof(identifier));
        
        if (powerKw <= 0)
            throw new ArgumentException("Power output must be positive.", nameof(powerKw));

        if (tariff < 0)
            throw new ArgumentException("Tariff cannot be negative.", nameof(tariff));

        Identifier = identifier.Trim();
        BayLabel = bayLabel?.Trim() ?? string.Empty;
        Connector = connector;
        PowerKw = powerKw;
        Tariff = tariff;
    }

    public void SetStatus(ChargerStatus status)
    {
        Status = status;
    }
}
