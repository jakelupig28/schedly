Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\User\schedly\frontend\assets\app_icon.png"
$bytes = [System.IO.File]::ReadAllBytes($srcPath)
$ms = New-Object System.IO.MemoryStream(,$bytes)
$src = [System.Drawing.Bitmap]::FromStream($ms)

$width = $src.Width
$height = $src.Height
Write-Host "Original Image: $width x $height"

# Find bounding box of the blue graphic
$minX = $width
$minY = $height
$maxX = 0
$maxY = 0

for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $c = $src.GetPixel($x, $y)
        # Blue line pixels
        if ($c.B -gt 150 -and $c.R -lt 120) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

Write-Host "Blue Bounding Box: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY"
$cropW = $maxX - $minX + 1
$cropH = $maxY - $minY + 1
Write-Host "Cropped dimensions: $cropW x $cropH"

# Helper function to generate full-bleed icon at a given size
function Create-FullBleedIcon([int]$targetSize, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap($targetSize, $targetSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # Solid pure white background spanning 100% of canvas with 0 margins and no inner rounded rectangle or shadow
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillRectangle($brush, 0, 0, $targetSize, $targetSize)
    $brush.Dispose()

    # The blue icon graphic fills 72% of the target icon size (standard Android safe adaptive zone)
    $destScale = [Math]::Min(($targetSize * 0.72) / $cropW, ($targetSize * 0.72) / $cropH)
    $destW = [int]($cropW * $destScale)
    $destH = [int]($cropH * $destScale)
    $destX = [int](($targetSize - $destW) / 2)
    $destY = [int](($targetSize - $destH) / 2)

    $srcRect = New-Object System.Drawing.Rectangle($minX, $minY, $cropW, $cropH)
    $destRect = New-Object System.Drawing.Rectangle($destX, $destY, $destW, $destH)

    $g.DrawImage($src, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Saved: $outPath ($targetSize x $targetSize)"
}

# 1. Update assets/app_icon.png (1024x1024)
Create-FullBleedIcon 1024 "c:\Users\User\schedly\frontend\assets\app_icon.png"

# 2. Update Android mipmap icons
$mipmaps = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($folder in $mipmaps.Keys) {
    $size = $mipmaps[$folder]
    $dir = "c:\Users\User\schedly\frontend\android\app\src\main\res\$folder"
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
    Create-FullBleedIcon $size "$dir\ic_launcher.png"
}

$src.Dispose()
$ms.Dispose()
Write-Host "All Full-Bleed App Icons Created Successfully!"
