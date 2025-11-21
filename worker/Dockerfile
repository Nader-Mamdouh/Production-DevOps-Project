# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copy only project files and restore dependencies first for layer caching
COPY *.csproj ./
RUN dotnet restore

# Copy rest of the source code
COPY . ./

# Publish the project in Release configuration
RUN dotnet publish -c Release -o /app/publish --no-restore

# Stage 2: Runtime (non-root) with updated Alpine base and package upgrades
FROM mcr.microsoft.com/dotnet/runtime:7.0-alpine AS runtime

# Upgrade Alpine packages to fix known vulnerabilities
RUN apk update && apk upgrade && apk add --no-cache bash

# Create a non-root user
RUN adduser -D -h /app appuser

WORKDIR /app

USER appuser

# Copy published output from build stage with ownership
COPY --from=build --chown=appuser:appuser /app/publish .

# Run the app
ENTRYPOINT ["dotnet", "Worker.dll"]
