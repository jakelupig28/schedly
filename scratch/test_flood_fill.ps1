Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
$w = $bmp.Width
$h = $bmp.Height

$bgColor = [System.Drawing.Color]::FromArgb(255, 206, 162, 248)

# Any pixel that is dark/black near the 4 corners (outer squircle frame) should become the background color
$outBmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Queue-based flood fill from (0,0), (w-1,0), (0,h-1), (w-1,h-1)
$visited = New-Object 'bool[,]' $w, $h

$queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
$queue.Enqueue((New-Object System.Drawing.Point(0, 0)))
$queue.Enqueue((New-Object System.Drawing.Point($w - 1, 0)))
$queue.Enqueue((New-Object System.Drawing.Point(0, $h - 1)))
$queue.Enqueue((New-Object System.Drawing.Point($w - 1, $h - 1)))

# Also seed edges that are black
for ($x = 0; $x -lt $w; $x++) {
    if ($bmp.GetPixel($x, 0).R -lt 50) { $queue.Enqueue((New-Object System.Drawing.Point($x, 0))) }
    if ($bmp.GetPixel($x, $h - 1).R -lt 50) { $queue.Enqueue((New-Object System.Drawing.Point($x, $h - 1))) }
}
for ($y = 0; $y -lt $h; $y++) {
    if ($bmp.GetPixel(0, $y).R -lt 50) { $queue.Enqueue((New-Object System.Drawing.Point(0, $y))) }
    if ($bmp.GetPixel($w - 1, $y).R -lt 50) { $queue.Enqueue((New-Object System.Drawing.Point($w - 1, $y))) }
}

while ($queue.Count -gt 0) {
    $p = $queue.Dequeue()
    if ($p.X -lt 0 -or $p.X -ge $w -or $p.Y -lt 0 -or $p.Y -ge $h) { continue }
    if ($visited[$p.X, $p.Y]) { continue }
    $visited[$p.X, $p.Y] = $true

    $c = $bmp.GetPixel($p.X, $p.Y)
    # Check if dark/black frame pixel (outer frame)
    # Note: ensure we don't bleed into the sleeve (bottom left sleeve is R~160, G~100, B~240 with black outline)
    # Outer frame is pure black (R < 30, G < 30, B < 30) or near the very edge
    if ($c.R -lt 45 -and $c.G -lt 45 -and $c.B -lt 45) {
        $queue.Enqueue((New-Object System.Drawing.Point($p.X + 1, $p.Y)))
        $queue.Enqueue((New-Object System.Drawing.Point($p.X - 1, $p.Y)))
        $queue.Enqueue((New-Object System.Drawing.Point($p.X, $p.Y + 1)))
        $queue.Enqueue((New-Object System.Drawing.Point($p.X, $p.Y - 1)))
    }
}

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        if ($visited[$x, $y]) {
            $outBmp.SetPixel($x, $y, $bgColor)
        } else {
            $outBmp.SetPixel($x, $y, $bmp.GetPixel($x, $y))
        }
    }
}

$testOut = "C:\Users\User\.gemini\antigravity-ide\brain\2022d21f-7f4f-418e-b84c-dc148449d45a\app_icon2_cleaned.png"
$outBmp.Save($testOut, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved cleaned icon to: $testOut"

$bmp.Dispose()
$outBmp.Dispose()
