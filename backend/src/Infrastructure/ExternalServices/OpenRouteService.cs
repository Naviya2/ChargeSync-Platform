using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Application.ReservationPlanning.Models;
using Application.ReservationPlanning.Services;

namespace Infrastructure.ExternalServices;

public sealed class OpenRouteService : IRoutingService
{
    private readonly HttpClient _httpClient;

    public OpenRouteService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<RouteMatrixResponse> GetMatrixAsync(RouteMatrixRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Destinations.Count == 0)
        {
            return new RouteMatrixResponse();
        }

        // ORS format: [longitude, latitude]
        var locations = new List<double[]>
        {
            new[] { request.Origin.Longitude, request.Origin.Latitude }
        };

        foreach (var dest in request.Destinations)
        {
            locations.Add(new[] { dest.Longitude, dest.Latitude });
        }

        var payload = new
        {
            locations = locations,
            sources = new[] { 0 },
            metrics = new[] { "distance", "duration" }
        };

        var response = await _httpClient.PostAsJsonAsync("v2/matrix/driving-car", payload, cancellationToken);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OrsMatrixResponse>(cancellationToken: cancellationToken);
        var matrixResponse = new RouteMatrixResponse();

        if (result?.Distances != null && result.Durations != null && 
            result.Distances.Length > 0 && result.Durations.Length > 0)
        {
            var distances = result.Distances[0];
            var durations = result.Durations[0];

            // Source is index 0, destinations start at index 1
            for (int i = 1; i < distances.Length; i++)
            {
                matrixResponse.Elements.Add(new RouteMatrixElement
                {
                    DestinationIndex = i - 1,
                    DistanceMeters = distances[i],
                    DurationSeconds = durations[i]
                });
            }
        }

        return matrixResponse;
    }

    public async Task<RouteDirectionsResponse> GetDirectionsAsync(RouteDirectionsRequest request, CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            coordinates = new[]
            {
                new[] { request.Origin.Longitude, request.Origin.Latitude },
                new[] { request.Destination.Longitude, request.Destination.Latitude }
            }
        };

        var response = await _httpClient.PostAsJsonAsync("v2/directions/driving-car/geojson", payload, cancellationToken);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OrsDirectionsResponse>(cancellationToken: cancellationToken);
        
        var dirResponse = new RouteDirectionsResponse();

        if (result?.Features != null && result.Features.Count > 0)
        {
            var feature = result.Features[0];
            if (feature.Properties != null && feature.Properties.Summary != null)
            {
                dirResponse.DistanceMeters = feature.Properties.Summary.Distance;
                dirResponse.DurationSeconds = feature.Properties.Summary.Duration;
            }

            if (feature.Geometry != null && feature.Geometry.Coordinates != null)
            {
                dirResponse.GeometryCoordinates = feature.Geometry.Coordinates;
            }
        }

        return dirResponse;
    }

    private class OrsMatrixResponse
    {
        [JsonPropertyName("distances")]
        public double[][]? Distances { get; set; }

        [JsonPropertyName("durations")]
        public double[][]? Durations { get; set; }
    }

    private class OrsDirectionsResponse
    {
        [JsonPropertyName("features")]
        public List<OrsFeature>? Features { get; set; }
    }

    private class OrsFeature
    {
        [JsonPropertyName("properties")]
        public OrsProperties? Properties { get; set; }

        [JsonPropertyName("geometry")]
        public OrsGeometry? Geometry { get; set; }
    }

    private class OrsProperties
    {
        [JsonPropertyName("summary")]
        public OrsSummary? Summary { get; set; }
    }

    private class OrsSummary
    {
        [JsonPropertyName("distance")]
        public double Distance { get; set; }

        [JsonPropertyName("duration")]
        public double Duration { get; set; }
    }

    private class OrsGeometry
    {
        [JsonPropertyName("coordinates")]
        public List<double[]>? Coordinates { get; set; }
    }
}
