using Domain.Common;
using Domain.Enums;
using Domain.Users;

namespace Domain.Entities;

public class Station : AuditableEntity
{
    private Station() { }

    private Station(string name, string address, double latitude, double longitude, Guid ownerId)
    {
        Name = name;
        Address = address;
        Latitude = latitude;
        Longitude = longitude;
        OwnerId = ownerId;
        Status = StationStatus.Pending;
        Chargers = new List<Charger>();
        OperatingHours = new List<OperatingHour>();
    }

    public Guid Id { get; private set; }
    public string Name { get; private set; } = null!;
    public string Address { get; private set; } = null!;
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }
    public Guid OwnerId { get; private set; }
    
    public StationStatus Status { get; private set; }
    public string? RejectionReason { get; private set; }

    public ICollection<Charger> Chargers { get; private set; } = null!;
    public ICollection<OperatingHour> OperatingHours { get; private set; } = null!;

    public User Owner { get; private set; } = null!;

    public static Station Create(string name, string address, double latitude, double longitude, Guid ownerId)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Station name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(address))
            throw new ArgumentException("Station address is required.", nameof(address));

        return new Station(name.Trim(), address.Trim(), latitude, longitude, ownerId);
    }

    public void Approve()
    {
        Status = StationStatus.Active;
        RejectionReason = null;
    }

    public void Reject(string reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("Rejection reason is required.", nameof(reason));

        Status = StationStatus.Rejected;
        RejectionReason = reason;
    }
    
    public void Suspend()
    {
        Status = StationStatus.Suspended;
    }

    public void UpdateDetails(string name, string address, double latitude, double longitude)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Station name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(address))
            throw new ArgumentException("Station address is required.", nameof(address));

        Name = name.Trim();
        Address = address.Trim();
        Latitude = latitude;
        Longitude = longitude;
    }

    public void AddCharger(Charger charger)
    {
        Chargers.Add(charger);
    }
    
    public void UpdateOperatingHours(List<OperatingHour> newHours)
    {
        OperatingHours.Clear();
        foreach (var oh in newHours)
        {
            OperatingHours.Add(oh);
        }
    }
}
