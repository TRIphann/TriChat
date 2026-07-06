# =============================================================================
# Helpers to encode / decode the Firebase service-account JSON key so it can be
# carried inside the FIREBASE_CREDENTIALS_BASE64 environment variable.
#
# Usage (from repo root, with PowerShell):
#   pwsh scripts/encode-firebase-key.ps1
#
# Then copy the printed single-line base64 string into your `.env` file as
# `FIREBASE_CREDENTIALS_BASE64=...`. Restore (verify) at any time:
#   pwsh scripts/encode-firebase-key.ps1 -Decode
# =============================================================================

param(
    [switch]$Decode
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$candidates = @(
    Join-Path $repoRoot "backend\FirebaseCredentials\serviceAccountKey.json"
    Join-Path $repoRoot "backend\config\serviceAccountKey.json"
    Join-Path $repoRoot "backend\serviceAccountKey.json"
)
$keyFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $keyFile) {
    Write-Error "Could not find serviceAccountKey.json. Looked at:`n$($candidates -join "`n")"
    exit 1
}

Write-Host "Using: $keyFile"

if ($Decode) {
    $env:FIREBASE_CREDENTIALS_BASE64 = $args[0]
    if (-not $env:FIREBASE_CREDENTIALS_BASE64) {
        Write-Error "Pass the base64 string as the first argument to decode."
    }
    $bytes = [Convert]::FromBase64String($env:FIREBASE_CREDENTIALS_BASE64)
    [System.IO.File]::WriteAllBytes("$repoRoot\serviceAccountKey.decoded.json", $bytes)
    Write-Host "Wrote serviceAccountKey.decoded.json"
    exit 0
}

$bytes = [System.IO.File]::ReadAllBytes($keyFile)
$b64   = [Convert]::ToBase64String($bytes)
Write-Host ""
Write-Host "================ FIREBASE_CREDENTIALS_BASE64 ================"
Write-Host $b64
Write-Host "============================================================="
Write-Host ""
Write-Host "It is safe to paste the line above into .env (it is base64, not a secret in itself)."
