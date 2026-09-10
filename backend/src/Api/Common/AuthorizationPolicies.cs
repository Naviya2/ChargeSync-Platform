namespace Api.Common;

/// <summary>Named authorization policies (see <c>Program.cs</c>).</summary>
public static class AuthorizationPolicies
{
    public const string Admin = "Admin";
    public const string StationOwner = "StationOwner";
    public const string SupportManager = "SupportManager";
    public const string Driver = "Driver";
}
