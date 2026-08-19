Copy-Item "c:\Users\User\schedly\frontend\prototype\app_icon.png" "c:\Users\User\schedly\frontend\assets\app_icon.png" -Force

Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\User\schedly\frontend\assets\app_icon.png"
$src = [System.Drawing.Image]::FromFile($srcPath)

$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($k in $sizes.Keys) {
    $dim = $sizes[$k]
    $destDir = "c:\Users\User\schedly\frontend\android\app\src\main\res\$k"
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $bmp = New-Object System.Drawing.Bitmap $dim, $dim
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $dim, $dim)
    
    $destFile = Join-Path $destDir "ic_launcher.png"
    $bmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $g.Dispose()
    Write-Host "Generated $destFile ($dim x $dim)"
}

$src.Dispose()
Write-Host "All launcher icons generated successfully."
