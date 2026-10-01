using AgentClient;
using AgentClient.Models;
using Api.Authentication;
using Api.Controllers;
using Application.Common.Interfaces;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace UnitTests.ReservationPlanning.Tests;

public class ChargingPlansControllerTests
{
    private readonly Mock<IPlanningAgentClient> _mockAgentClient;
    private readonly Mock<ICurrentUser> _mockCurrentUser;
    private readonly Mock<ILogger<ChargingPlansController>> _mockLogger;
    private readonly AppDbContext _dbContext;
    private readonly ChargingPlansController _controller;

    public ChargingPlansControllerTests()
    {
        _mockAgentClient = new Mock<IPlanningAgentClient>();
        _mockCurrentUser = new Mock<ICurrentUser>();
        _mockLogger = new Mock<ILogger<ChargingPlansController>>();
        _dbContext = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

        _controller = new ChargingPlansController(
            _mockAgentClient.Object,
            _mockCurrentUser.Object,
            _mockLogger.Object,
            _dbContext);
    }

    [Fact]
    public async Task GenerateChargingPlan_ReturnsOk_WhenAgentSucceeds()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _mockCurrentUser.Setup(u => u.Id).Returns(userId);

        var request = new PlanningRequest(
            null,
            DateTime.UtcNow.AddHours(2),
            20,
            "Balanced",
            "v-123",
            null,
            null,
            null,
            null
        );

        var expectedResponse = new PlanningResponse(
            "p-1",
            new List<ItineraryStep>(),
            false,
            "Looks good"
        );

        _mockAgentClient
            .Setup(c => c.GenerateChargingPlanAsync(It.Is<PlanningRequest>(r => r.DriverId == userId.ToString()), It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedResponse);

        // Act
        var result = await _controller.GenerateChargingPlan(request, CancellationToken.None);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var responseValue = Assert.IsType<PlanningResponse>(okResult.Value);
        Assert.Equal(expectedResponse.PlanId, responseValue.PlanId);
    }

    [Fact]
    public async Task GenerateChargingPlan_Returns503_WhenAgentFails()
    {
        // Arrange
        _mockCurrentUser.Setup(u => u.Id).Returns(Guid.NewGuid());

        var request = new PlanningRequest(
            null,
            DateTime.UtcNow.AddHours(2),
            20,
            "Balanced",
            "v-123",
            null,
            null,
            null,
            null
        );

        _mockAgentClient
            .Setup(c => c.GenerateChargingPlanAsync(It.IsAny<PlanningRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((PlanningResponse?)null);

        // Act
        var result = await _controller.GenerateChargingPlan(request, CancellationToken.None);

        // Assert
        var statusCodeResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(503, statusCodeResult.StatusCode);
    }
}
