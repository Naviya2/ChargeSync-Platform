namespace Application.ReservationPlanning.Models;

public sealed class RoutingCoordinate
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public sealed class RouteMatrixRequest
{
    public RoutingCoordinate Origin { get; set; } = null!;
    public List<RoutingCoordinate> Destinations { get; set; } = new();
}

public sealed class RouteMatrixResponse
{
    public List<RouteMatrixElement> Elements { get; set; } = new();
}

public sealed class RouteMatrixElement
{
    public int DestinationIndex { get; set; }
    public double DistanceMeters { get; set; }
    public double DurationSeconds { get; set; }
}

public sealed class RouteDirectionsRequest
{
    public RoutingCoordinate Origin { get; set; } = null!;
    public RoutingCoordinate Destination { get; set; } = null!;
}

public sealed class RouteDirectionsResponse
{
    public double DistanceMeters { get; set; }
    public double DurationSeconds { get; set; }
    
    /// <summary>
    /// GeoJSON LineString coordinates. Inner array is [longitude, latitude].
    /// </summary>
    public List<double[]> GeometryCoordinates { get; set; } = new();
}
