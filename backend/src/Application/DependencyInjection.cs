using Application.Authentication;
using Application.Common.Security;
using Application.Users;
using Microsoft.Extensions.DependencyInjection;

namespace Application;

public static class DependencyInjection
{
    /// <summary>Registers Application-layer services (use cases).</summary>
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IResourceGuard, ResourceGuard>();

        services.AddScoped<Application.Stations.IStationService, Application.Stations.StationService>();
        services.AddScoped<Application.Stations.IAvailabilityService, Application.Stations.AvailabilityService>();
        services.AddScoped<Application.Admin.IAdminStationService, Application.Admin.AdminStationService>();

        return services;
    }
}
