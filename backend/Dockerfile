# Multi-stage Dockerfile for TriChat backend.
#
# Stage 1: build → restore + publish Release
# Stage 2: runtime → minimal ASP.NET image + entrypoint script that
#           materialises secrets from env vars before launch.
#
# Build context MUST be the `backend/` folder (see docker-compose.yml):
#   docker build -t trichat-backend backend
#
# Or, if building from the repo root:
#   docker build -t trichat-backend -f backend/Dockerfile backend

# -------------------- 1. build --------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj first for docker layer cache.
COPY backend.csproj ./
RUN dotnet restore backend.csproj

# Copy rest of the source.
COPY . ./
RUN dotnet publish backend.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# -------------------- 2. runtime --------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# base64-decode tool is bundled in the base image; no apt needed.

# Remove appsettings.json so the entrypoint generates a fresh one from env vars.
# ASP.NET on Production always prefers env vars, so the file is not needed.
RUN rm -f /app/appsettings.json

# Copy the published artefact + our entrypoint.
COPY --from=build /app/publish ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ASP.NET service listens on this port (matches appsettings.json).
EXPOSE 5244

# Bind to 0.0.0.0 so Docker port-mapping works.
ENV ASPNETCORE_URLS=http://+:5244 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_NOLOGO=true

ENTRYPOINT ["docker-entrypoint.sh"]
