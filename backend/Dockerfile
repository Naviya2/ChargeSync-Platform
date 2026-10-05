# Multi-stage minimal build for ASP.NET Core 8 Web API
# Isolated to backend/ - no external orchestration or docker-compose required.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files first to maximize Docker layer caching
COPY ChargeSync.Backend.sln ./
COPY src/Domain/Domain.csproj src/Domain/
COPY src/Application/Application.csproj src/Application/
COPY src/Infrastructure/Infrastructure.csproj src/Infrastructure/
COPY src/AgentClient/AgentClient.csproj src/AgentClient/
COPY src/Api/Api.csproj src/Api/

# Restore dependencies for Api
RUN dotnet restore src/Api/Api.csproj

# Copy application source code
COPY src/ src/

# Build and publish release binaries
WORKDIR /src/src/Api
RUN dotnet publish -c Release -o /app/publish --no-restore

# Lightweight runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Render dynamically sets $PORT; Program.cs reads PORT or defaults to ASPNETCORE_URLS
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "Api.dll"]
