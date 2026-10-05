namespace Infrastructure.Persistence;

/// <summary>
/// Optional bootstrap data, bound from the <c>Seed</c> configuration section.
/// <see cref="AdminPassword"/> is a secret — supply it outside source control.
/// If email or password is missing, the corresponding account is not seeded.
/// </summary>
public sealed class SeedOptions
{
    public const string SectionName = "Seed";

    // ── Admin ─────────────────────────────────────────────────────────────────
    public string? AdminEmail { get; init; }
    public string? AdminPassword { get; init; }
    public string AdminFullName { get; init; } = "Platform Administrator";

    // ── Support Manager ───────────────────────────────────────────────────────
    public string? SupportManagerEmail { get; init; }
    public string? SupportManagerPassword { get; init; }
    public string SupportManagerFullName { get; init; } = "Support Manager";
}
