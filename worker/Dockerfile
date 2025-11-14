# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# Stage 2: Runtime (non-root)
FROM mcr.microsoft.com/dotnet/runtime:7.0-alpine AS runtime
RUN adduser -D -h /app appuser
WORKDIR /app
USER appuser

COPY --from=build --chown=appuser:appuser /app/publish .

ENTRYPOINT ["dotnet", "Worker.dll"]
