namespace Infrastructure.Persistence;

/// <summary>
/// Optional bootstrap data, bound from the <c>Seed</c> configuration section.
/// <see cref="AdminPassword"/> is a secret — supply it outside source control.
/// If email or password is missing, no admin is seeded.
/// </summary>
public sealed class SeedOptions
{
    public const string SectionName = "Seed";

    public string? AdminEmail { get; init; }

    public string? AdminPassword { get; init; }

    public string AdminFullName { get; init; } = "Platform Administrator";
}
