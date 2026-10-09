using Api.Controllers;
using Application.Common.Interfaces;
using Application.Stations;
using Application.Stations.Models;
using Domain.Enums;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace UnitTests.Stations;

public sealed class StationsControllerTests
{
    private readonly Mock<IStationService> _stationServiceMock;
    private readonly Mock<ICurrentUser> _currentUserMock;
    private readonly StationsController _controller;

    public StationsControllerTests()
    {
        _stationServiceMock = new Mock<IStationService>();
        _currentUserMock = new Mock<ICurrentUser>();
        _controller = new StationsController(_stationServiceMock.Object, _currentUserMock.Object);
    }

    [Fact]
    public async Task GetAllStations_ReturnsOkResult_WithStationsList()
    {
        // Arrange
        var mockStations = new List<StationDto>
        {
            new StationDto { Id = Guid.NewGuid(), Name = "Station 1" },
            new StationDto { Id = Guid.NewGuid(), Name = "Station 2" }
        };

        _stationServiceMock
            .Setup(s => s.GetAllStationsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockStations);

        // Act
        var result = await _controller.GetAllStations(CancellationToken.None);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnValue = Assert.IsType<List<StationDto>>(okResult.Value);
        Assert.Equal(2, returnValue.Count);
    }

    [Fact]
    public async Task RegisterStation_ReturnsCreatedResponse()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        _currentUserMock.Setup(u => u.Id).Returns(ownerId);

        var request = new RegisterStationRequest
        {
            Name = "New Station",
            Address = "Address",
            Latitude = 1.0,
            Longitude = 2.0,
            DocumentUrls = new List<string>()
        };

        var createdStation = new StationDto { Id = Guid.NewGuid(), Name = "New Station" };

        _stationServiceMock
            .Setup(s => s.RegisterStationAsync(ownerId, request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(createdStation);

        // Act
        var result = await _controller.RegisterStation(request, CancellationToken.None);

        // Assert
        var createdResult = Assert.IsType<CreatedAtActionResult>(result);
        var returnValue = Assert.IsType<StationDto>(createdResult.Value);
        Assert.Equal(createdStation.Id, returnValue.Id);
    }

    [Fact]
    public async Task GetStationById_ReturnsNotFound_WhenStationMissing()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        _currentUserMock.Setup(u => u.Id).Returns(ownerId);

        _stationServiceMock
            .Setup(s => s.GetStationByIdAsync(It.IsAny<Guid>(), ownerId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((StationDto?)null);

        // Act
        var result = await _controller.GetStationById(Guid.NewGuid(), CancellationToken.None);

        // Assert
        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task AddCharger_ReturnsOk_WhenSuccessful()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        var stationId = Guid.NewGuid();
        _currentUserMock.Setup(u => u.Id).Returns(ownerId);

        var request = new AddChargerRequest { Identifier = "CHG-1", Connector = ConnectorType.Type2, PowerKw = 50.0m };
        var expectedDto = new ChargerDto { Id = Guid.NewGuid(), Identifier = "CHG-1" };

        _stationServiceMock
            .Setup(s => s.AddChargerAsync(stationId, ownerId, request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedDto);

        // Act
        var result = await _controller.AddCharger(stationId, request, CancellationToken.None);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnValue = Assert.IsType<ChargerDto>(okResult.Value);
        Assert.Equal(expectedDto.Id, returnValue.Id);
    }

    [Fact]
    public async Task UpdateOperatingHours_ReturnsNoContent_WhenSuccessful()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        var stationId = Guid.NewGuid();
        _currentUserMock.Setup(u => u.Id).Returns(ownerId);

        var request = new List<OperatingHourDto> 
        { 
            new OperatingHourDto { DayOfWeek = 1, IsEnabled = true, OpenTime = new TimeSpan(8, 0, 0), CloseTime = new TimeSpan(20, 0, 0) } 
        };

        _stationServiceMock
            .Setup(s => s.UpdateOperatingHoursAsync(stationId, ownerId, request, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        // Act
        var result = await _controller.UpdateOperatingHours(stationId, request, CancellationToken.None);

        // Assert
        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task AddMaintenanceWindow_ReturnsOk_WhenSuccessful()
    {
        // Arrange
        var ownerId = Guid.NewGuid();
        var chargerId = Guid.NewGuid();
        _currentUserMock.Setup(u => u.Id).Returns(ownerId);

        var request = new MaintenanceWindowDto { Reason = "Routine Check", StartTime = DateTimeOffset.UtcNow, EndTime = DateTimeOffset.UtcNow.AddHours(2) };
        var expectedMw = new MaintenanceWindowDto { Id = Guid.NewGuid(), Reason = "Routine Check" };

        _stationServiceMock
            .Setup(s => s.AddMaintenanceWindowAsync(chargerId, ownerId, request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedMw);

        // Act
        var result = await _controller.AddMaintenanceWindow(chargerId, request, CancellationToken.None);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var returnValue = Assert.IsType<MaintenanceWindowDto>(okResult.Value);
        Assert.Equal(expectedMw.Id, returnValue.Id);
    }
}
