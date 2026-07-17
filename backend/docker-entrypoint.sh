#!/bin/sh
set -e

# appsettings.json is removed in the Dockerfile; we reconstruct it from env vars here.
# This allows Render (or any Docker host) to inject secrets via env vars without
# baking them into the image.

APPSETTINGS="/app/appsettings.json"

# Helper: decode a base64 string and write to a file if the env var is set.
write_secret() {
    varname="$1"
    filepath="$2"
    value=$(printenv "$varname" 2>/dev/null || true)
    if [ -n "$value" ]; then
        echo "$value" | base64 -d > "$filepath" 2>/dev/null || echo "$value" > "$filepath"
    fi
}

# Decode Firebase credentials if provided as base64.
if [ -n "$FIREBASE_CREDENTIALS_BASE64" ]; then
    mkdir -p /app/FirebaseCredentials
    echo "$FIREBASE_CREDENTIALS_BASE64" | base64 -d > /app/FirebaseCredentials/serviceAccountKey.json
fi

# Decode Cloudinary credentials if provided as base64.
if [ -n "$CLOUDINARY_URL_BASE64" ]; then
    write_secret "CLOUDINARY_URL_BASE64" "/app/cloudinary.env"
    # Cloudinary URL is read from CLOUDINARY_URL env var by the app.
    if [ -f /app/cloudinary.env ]; then
        export CLOUDINARY_URL=$(cat /app/cloudinary.env)
    fi
fi

# Decode Redis password if provided as base64.
if [ -n "$REDIS_PASSWORD_BASE64" ]; then
    export REDIS_PASSWORD=$(echo "$REDIS_PASSWORD_BASE64" | base64 -d)
fi

# Write appsettings.json from environment variables.
# Only write if the file doesn't exist (already removed in Dockerfile, but as a safety check).
if [ ! -f "$APPSETTINGS" ]; then
    cat > "$APPSETTINGS" << 'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Firebase": {
    "ProjectId": "${FIREBASE_PROJECT_ID}",
    "CredentialsFilePath": "${FIREBASE_CREDENTIALS_PATH:-/app/FirebaseCredentials/serviceAccountKey.json}"
  },
  "Redis": {
    "ConnectString": "${REDIS_CONNECT_STRING}"
  },
  "Cloudinary": {
    "CloudName": "${CLOUDINARY_CLOUD_NAME}",
    "ApiKey": "${CLOUDINARY_API_KEY}",
    "ApiSecret": "${CLOUDINARY_API_SECRET}"
  },
  "Urls": {
    "LocalBaseUrl": "${LOCAL_BASE_URL:-http://localhost:5244}"
  }
}
EOF

    # Substitute environment variables.
    envsubst < "$APPSETTINGS" > "${APPSETTINGS}.tmp" && mv "${APPSETTINGS}.tmp" "$APPSETTINGS"
fi

# Execute the ASP.NET application.
exec dotnet /app/backend.dll
