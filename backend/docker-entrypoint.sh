#!/usr/bin/env bash
#
# docker-entrypoint.sh — materialise secrets into files BEFORE starting
# the ASP.NET Core app. This lets us ship the Docker image without ever
# baking `appsettings.json` or `serviceAccountKey.json` into a layer.
#
# Conventions for env vars (double underscore = colon in nested keys):
#
#   Firebase__ProjectId                      -> appsettings: Firebase:ProjectId
#   Firebase__DatabaseId                     -> appsettings: Firebase:DatabaseId  (optional)
#   Firebase__CredentialsBase64              -> decoded to FirebaseCredentials/serviceAccountKey.json
#                                              (path matches appsettings default)
#
#   Redis__ConnectString                     -> appsettings: Redis:ConnectString
#   Cloudinary__CloudName / ApiKey / ApiSecret
#   Groq__ApiKey                             -> appsettings: Groq:ApiKey
#   Groq__Model                              -> optional, default "llama-3.1-8b-instant"
#   Smtp__Host / Port / Username / Password / From
#   Agora__AppId / AppCertificate (note: backend doesn't use Agora directly today,
#                                    but web/mobile need it — listed for completeness)
#
#   BackendAllowedOrigins                    -> CSV; injected into CORS policy

set -euo pipefail

CONFIG_FILE="/app/appsettings.json"
CREDS_DIR="/app/FirebaseCredentials"
CREDS_FILE="${CREDS_DIR}/serviceAccountKey.json"

mkdir -p "${CREDS_DIR}"

# -- 1. Materialise Firebase service-account key from env ----------
if [[ -n "${Firebase__CredentialsBase64:-}" ]]; then
    echo "[entrypoint] decoding Firebase__CredentialsBase64 -> ${CREDS_FILE}"
    echo -n "${Firebase__CredentialsBase64}" | base64 -d > "${CREDS_FILE}"
    chmod 600 "${CREDS_FILE}"
elif [[ ! -f "${CREDS_FILE}" ]]; then
    echo "[entrypoint] WARNING: no Firebase credentials supplied via Firebase__CredentialsBase64"
    echo "[entrypoint]          and ${CREDS_FILE} does not exist — FirebaseAdmin will fail at startup."
fi

# -- 2. Materialise appsettings.json --------------------------------
if [[ -f "${CONFIG_FILE}" ]]; then
    echo "[entrypoint] using existing ${CONFIG_FILE}"
else
    echo "[entrypoint] synthesising ${CONFIG_FILE} from environment variables"

    # Use heredoc with substitutions; null defaults via :- empty.
    cat > "${CONFIG_FILE}" <<EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.AspNetCore.SignalR": "Information"
    }
  },
  "AllowedHosts": "*",
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning",
        "Microsoft.AspNetCore.SignalR": "Information"
      }
    }
  },
  "Firebase": {
    "ProjectId":           "${Firebase__ProjectId:-}",
    "DatabaseId":          "${Firebase__DatabaseId:-}",
    "CredentialsFilePath": "FirebaseCredentials/serviceAccountKey.json"
  },
  "Redis": {
    "ConnectString": "${Redis__ConnectString:-redis:6379}"
  },
  "Cloudinary": {
    "CloudName": "${Cloudinary__CloudName:-}",
    "ApiKey":    "${Cloudinary__ApiKey:-}",
    "ApiSecret": "${Cloudinary__ApiSecret:-}"
  },
  "Groq": {
    "ApiKey": "${Groq__ApiKey:-}",
    "Model":  "${Groq__Model:-llama-3.1-8b-instant}"
  },
  "Smtp": {
    "Host":     "${Smtp__Host:-smtp.gmail.com}",
    "Port":     "${Smtp__Port:-587}",
    "Username": "${Smtp__Username:-}",
    "Password": "${Smtp__Password:-}",
    "From":     "${Smtp__From:-${Smtp__Username:-}}"
  }
}
EOF
fi

# -- 3. Forward signal handling to dotnet ----------------------------
echo "[entrypoint] launching: dotnet backend.dll"
exec dotnet backend.dll
