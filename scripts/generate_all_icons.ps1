# Generate the TriChat master icon at 1024x1024 (non-maskable and maskable).
# Then resize to every platform-specific size.
$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSCommandPath
$tools   = Join-Path $root "tools"
$icondir = Join-Path $tools "icon-master"
New-Item -ItemType Directory -Force -Path $icondir | Out-Null

# --- Master 1024 ---
& (Join-Path $root "generate_trichat_icon.ps1") -Size 1024 -OutPath (Join-Path $icondir "master-1024.png") -Maskable $false
& (Join-Path $root "generate_trichat_icon.ps1") -Size 1024 -OutPath (Join-Path $icondir "master-1024-maskable.png") -Maskable $true

Add-Type -AssemblyName System.Drawing

function Resize-Icon {
    param(
        [string]$Source,
        [int]$Size,
        [string]$Dest
    )
    $src = [System.Drawing.Image]::FromFile($Source)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $Size, $Size)
    $g.Dispose()
    $bmp.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $src.Dispose()
    Write-Host "  -> $Dest ($Size px)"
}

# --- WEB ---
$webIcons = Join-Path $root "..\frontend\web\icons"
$webFavicon = Join-Path $root "..\frontend\web\favicon.png"

Write-Host "`n[WEB] Generating web icons..."
Resize-Icon (Join-Path $icondir "master-1024.png") 192 (Join-Path $webIcons "Icon-192.png")
Resize-Icon (Join-Path $icondir "master-1024.png") 512 (Join-Path $webIcons "Icon-512.png")
Resize-Icon (Join-Path $icondir "master-1024-maskable.png") 192 (Join-Path $webIcons "Icon-maskable-192.png")
Resize-Icon (Join-Path $icondir "master-1024-maskable.png") 512 (Join-Path $webIcons "Icon-maskable-512.png")
Resize-Icon (Join-Path $icondir "master-1024.png") 32  $webFavicon
Resize-Icon (Join-Path $icondir "master-1024.png") 180 (Join-Path $webIcons "apple-touch-icon.png")

# --- ANDROID ---
$androidRes = Join-Path $root "..\frontend\android\app\src\main\res"
Write-Host "`n[ANDROID] Generating mipmap icons..."
foreach ($pair in @(
    @{Density='mdpi';    Size=48},
    @{Density='hdpi';    Size=72},
    @{Density='xhdpi';   Size=96},
    @{Density='xxhdpi';  Size=144},
    @{Density='xxxhdpi'; Size=192}
)) {
    $dir = Join-Path $androidRes ("mipmap-" + $pair.Density)
    Resize-Icon (Join-Path $icondir "master-1024.png") $pair.Size (Join-Path $dir "ic_launcher.png")
}

# --- iOS ---
$iosAssets = Join-Path $root "..\frontend\ios\Runner\Assets.xcassets\AppIcon.appiconset"
Write-Host "`n[iOS] Generating AppIcon assets..."
$iosSizes = @(
    @{Name="Icon-App-20x20@1x.png";     Size=20},
    @{Name="Icon-App-20x20@2x.png";     Size=40},
    @{Name="Icon-App-20x20@3x.png";     Size=60},
    @{Name="Icon-App-29x29@1x.png";     Size=29},
    @{Name="Icon-App-29x29@2x.png";     Size=58},
    @{Name="Icon-App-29x29@3x.png";     Size=87},
    @{Name="Icon-App-40x40@1x.png";     Size=40},
    @{Name="Icon-App-40x40@2x.png";     Size=80},
    @{Name="Icon-App-40x40@3x.png";     Size=120},
    @{Name="Icon-App-60x60@2x.png";     Size=120},
    @{Name="Icon-App-60x60@3x.png";     Size=180},
    @{Name="Icon-App-76x76@1x.png";     Size=76},
    @{Name="Icon-App-76x76@2x.png";     Size=152},
    @{Name="Icon-App-83.5x83.5@2x.png"; Size=167},
    @{Name="Icon-App-1024x1024@1x.png"; Size=1024}
)
foreach ($s in $iosSizes) {
    Resize-Icon (Join-Path $icondir "master-1024.png") $s.Size (Join-Path $iosAssets $s.Name)
}

Write-Host "`nDone. TriChat icon set generated in black/white/gray tones."
