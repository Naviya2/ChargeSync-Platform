using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

public class Vehicle : AuditableEntity
{
    private Vehicle() { }

    private Vehicle(
        Guid ownerId,
        string make,
        string model,
        ConnectorType connector,
        decimal batteryCapacityKwh,
        decimal maxChargeRateKw,
        string? licensePlate)
    {
        OwnerId = ownerId;
        Make = make;
        Model = model;
        Connector = connector;
        BatteryCapacityKwh = batteryCapacityKwh;
        MaxChargeRateKw = maxChargeRateKw;
        LicensePlate = NormaliseOptional(licensePlate);
    }

    public Guid Id { get; private set; }
    public Guid OwnerId { get; private set; }
    public string Make { get; private set; } = null!;
    public string Model { get; private set; } = null!;
    public string? LicensePlate { get; private set; }
    public ConnectorType Connector { get; private set; }
    public decimal BatteryCapacityKwh { get; private set; }
    public decimal MaxChargeRateKw { get; private set; }

    public User Owner { get; private set; } = null!;

    public static Vehicle Create(
        Guid ownerId,
        string make,
        string model,
        ConnectorType connector,
        decimal batteryCapacityKwh,
        decimal maxChargeRateKw,
        string? licensePlate = null)
    {
        Validate(make, model, batteryCapacityKwh, maxChargeRateKw);

        return new Vehicle(
            ownerId,
            make.Trim(),
            model.Trim(),
            connector,
            batteryCapacityKwh,
            maxChargeRateKw,
            licensePlate);
    }

    public void UpdateDetails(
        string make,
        string model,
        ConnectorType connector,
        decimal batteryCapacityKwh,
        decimal maxChargeRateKw,
        string? licensePlate)
    {
        Validate(make, model, batteryCapacityKwh, maxChargeRateKw);

        Make = make.Trim();
        Model = model.Trim();
        Connector = connector;
        BatteryCapacityKwh = batteryCapacityKwh;
        MaxChargeRateKw = maxChargeRateKw;
        LicensePlate = NormaliseOptional(licensePlate);
    }

    private static void Validate(string make, string model, decimal batteryCapacityKwh, decimal maxChargeRateKw)
    {
        if (string.IsNullOrWhiteSpace(make))
            throw new ArgumentException("Make is required.", nameof(make));
        if (string.IsNullOrWhiteSpace(model))
            throw new ArgumentException("Model is required.", nameof(model));
        if (batteryCapacityKwh <= 0)
            throw new ArgumentException("Battery capacity must be positive.", nameof(batteryCapacityKwh));
        if (maxChargeRateKw <= 0)
            throw new ArgumentException("Maximum charge rate must be positive.", nameof(maxChargeRateKw));
    }

    private static string? NormaliseOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim().ToUpperInvariant();
}