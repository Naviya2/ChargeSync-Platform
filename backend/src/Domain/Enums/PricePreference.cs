namespace Domain.Enums;

/// <summary>
/// Price/speed sensitivity hint the driver provides when requesting an AI charging plan
/// (SRS §4.2 ChargingPlans — <c>PricePreference</c> column).
/// </summary>
public enum PricePreference
{
    /// <summary>Minimise cost; choose cheapest station even if further away.</summary>
    Cheapest,

    /// <summary>Balance between price and travel distance.</summary>
    Balanced,

    /// <summary>Prioritise shortest charging time and nearest station.</summary>
    Fastest
}
