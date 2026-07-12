param(
    [int]$Size = 1024,
    [string]$OutPath,
    [string]$SourcePng = (Join-Path $PSScriptRoot "..\frontend\assets\trichat_logo.png"),
    [bool]$Maskable = $false
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $SourcePng)) {
    Write-Error "Source logo not found: $SourcePng"
    exit 1
}

# === Brand palette (den / trang / xam, dung cho icon nền) ===
$bgColor      = [System.Drawing.Color]::FromArgb(255, 14, 14, 16)
$bgColorInner = [System.Drawing.Color]::FromArgb(255, 24, 24, 28)
$borderWhite  = [System.Drawing.Color]::FromArgb(40, 255, 255, 255)

$sizeD = [double]$Size

$bmp = New-Object System.Drawing.Bitmap($Size, $Size)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

# === Rounded square background ===
# Maskable: full-bleed + có safe-zone nội bộ
# Standard: pad nhỏ + bo góc lớn hơn
if ($Maskable) {
    $pad    = 0
    $radius = [int]($sizeD * 0.18)
    $logoInsetRatio = 0.30   # chừa 30% padding để nằm gọn trong safe-zone
} else {
    $pad    = [int]($sizeD * 0.06)
    $radius = [int]($sizeD * 0.22)
    $logoInsetRatio = 0.22   # full-bleed hơn
}

$bgRect = New-Object System.Drawing.Rectangle($pad, $pad, ($Size - 2 * $pad), ($Size - 2 * $pad))

$bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$bgPath.AddArc($bgRect.X, $bgRect.Y, $radius * 2, $radius * 2, 180, 90)
$bgPath.AddArc($bgRect.Right - $radius * 2, $bgRect.Y, $radius * 2, $radius * 2, 270, 90)
$bgPath.AddArc($bgRect.Right - $radius * 2, $bgRect.Bottom - $radius * 2, $radius * 2, $radius * 2, 0, 90)
$bgPath.AddArc($bgRect.X, $bgRect.Bottom - $radius * 2, $radius * 2, $radius * 2, 90, 90)
$bgPath.CloseFigure()

$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $bgRect,
    $bgColor,
    $bgColorInner,
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$g.FillPath($bgBrush, $bgPath)
$bgBrush.Dispose()

$borderPen = New-Object System.Drawing.Pen($borderWhite, [Math]::Max(1, $sizeD / 512))
$g.DrawPath($borderPen, $bgPath)
$borderPen.Dispose()

# === Composite source logo (PNG) lên trên nền ===
# Logo gốc có nền trong suốt; đặt vào vùng inner safe-zone
$logoBitmap = [System.Drawing.Image]::FromFile($SourcePng)

# Tính vị trí và kích thước logo bên trong
$logoPad = [int]($sizeD * $logoInsetRatio)
$logoRect = New-Object System.Drawing.Rectangle(
    $logoPad,
    $logoPad,
    ($Size - 2 * $logoPad),
    ($Size - 2 * $logoPad))
$g.DrawImage($logoBitmap, $logoRect)
$logoBitmap.Dispose()

$g.Dispose()
[void]$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Saved $OutPath ($Size x $Size, maskable=$Maskable)"
