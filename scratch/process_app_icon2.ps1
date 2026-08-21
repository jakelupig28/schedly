Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
$w = $bmp.Width
$h = $bmp.Height

Write-Host "Source Image Dimensions: $w x $h"

# Sample background purple color at various safe locations near top/bottom/sides
$samples = @(
    $bmp.GetPixel(300, 50),
    $bmp.GetPixel(600, 50),
    $bmp.GetPixel(900, 50),
    $bmp.GetPixel(1100, 300),
    $bmp.GetPixel(100, 300),
    $bmp.GetPixel(100, 800),
    $bmp.GetPixel(1150, 800)
)

foreach ($s in $samples) {
    Write-Host "Sample purple: R=$($s.R), G=$($s.G), B=$($s.B)"
}

# The purple background is very consistent: R=207, G=162, B=249 (#CFA2F9)
$bgR = 207
$bgG = 162
$bgB = 249

# Find bounding box of the graphic (hand, phone, document, pencil, and shadow)
$minX = $w; $minY = $h; $maxX = 0; $maxY = 0

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $c = $bmp.GetPixel($x, $y)
        # Skip the black frame at outer border
        if ($c.R -lt 40 -and $c.G -lt 40 -and $c.B -lt 40) {
            $distFromBorder = [Math]::Min([Math]::Min($x, $w - 1 - $x), [Math]::Min($y, $h - 1 - $y))
            if ($distFromBorder -lt 150) {
                continue
            }
        }

        # Check difference from purple background
        $diff = [Math]::Abs($c.R - $bgR) + [Math]::Abs($c.G - $bgG) + [Math]::Abs($c.B - $bgB)
        if ($diff -gt 15) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

Write-Host "Illustration Bounding Box: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY"
$illusW = $maxX - $minX + 1
$illusH = $maxY - $minY + 1
Write-Host "Illustration Size: $illusW x $illusH"

$bmp.Dispose()
