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
#   Redis__RestUrl / Redis__RestToken   -> appsettings: Redis:RestUrl / :RestToken
#                                        (Upstash REST API — not a TCP connect string)
#   Cloudinary__CloudName / ApiKey / ApiSecret
#   Groq__ApiKey                             -> appsettings: Groq:ApiKey
#   Groq__Model                              -> optional, default "llama-3.1-8b-instant"
#   Resend__ApiKey / Resend__From / Resend__FromName
#                                            -> appsettings: Resend:ApiKey / From / FromName
#                                            Email is delivered via Resend's HTTPS API
#                                            (https://api.resend.com/emails) because Render
#                                            free-tier blocks outbound TCP 25/465/587.
#   Agora__AppId / AppCertificate (note: backend doesn't use Agora directly today,
#                                    but web/mobile need it — listed for completeness)
#
#   BackendAllowedOrigins                    -> CSV; appended to CORS allowed origins

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
    "CredentialsFilePath": "FirebaseCredentials/serviceAccountKey.json",
    "CredentialsBase64":   "${Firebase__CredentialsBase64:-}"
  },
  "Redis": {
    "RestUrl":  "${Redis__RestUrl:-}",
    "RestToken": "${Redis__RestToken:-}"
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
  "Resend": {
    "ApiKey":    "${Resend__ApiKey:-}",
    "From":      "${Resend__From:-}",
    "FromName":  "${Resend__FromName:-TriChat}"
  },
  "AllowedCorsOrigins": "${BackendAllowedOrigins:-}"
}
EOF
fi

# -- 3. Forward signal handling to dotnet ----------------------------
echo "[entrypoint] launching: dotnet backend.dll"
exec dotnet backend.dll

