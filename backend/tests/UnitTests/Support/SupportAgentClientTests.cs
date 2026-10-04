using System.Net;
using AgentClient;
using Application.Support;

namespace UnitTests.Support;

public sealed class SupportAgentClientTests
{
    private sealed class Handler(Func<HttpResponseMessage> reply) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) => Task.FromResult(reply());
    }

    [Theory]
    [InlineData("{invalid", 200)]
    [InlineData("{}", 200)]
    [InlineData("{\"category\":\"Admin\",\"priority\":\"High\",\"explanation\":\"x\",\"draftReply\":\"x\"}", 200)]
    [InlineData("unavailable", 503)]
    public async Task InvalidOrUnavailableAgentReturnsFallbackSignal(string body, int status)
    {
        using var http = new HttpClient(new Handler(() => new HttpResponseMessage((HttpStatusCode)status) { Content = new StringContent(body) })) { BaseAddress = new Uri("http://agent.test") };
        Assert.Null(await new SupportAgentClient(http).AnalyzeAsync(new("Subject", "Description", [], []), default));
    }

    [Fact]
    public async Task TimeoutFallsBackButCallerCancellationPropagates()
    {
        using var http = new HttpClient(new Handler(() => throw new TaskCanceledException())) { BaseAddress = new Uri("http://agent.test") };
        var client = new SupportAgentClient(http);
        Assert.Null(await client.AnalyzeAsync(new("Subject", "Description", [], []), default));
        using var cts = new CancellationTokenSource(); cts.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => client.AnalyzeAsync(new("Subject", "Description", [], []), cts.Token));
    }
}
