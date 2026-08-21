$csharpCode = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class IconProcessor
{
    public static void CleanAndGenerate(string srcPath, string out1024, string mipmapBase)
    {
        using (var src = new Bitmap(srcPath))
        {
            int w = src.Width;
            int h = src.Height;
            
            var cleaned = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            Color bgPurple = Color.FromArgb(255, 206, 162, 248);

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color c = src.GetPixel(x, y);

                    // 1. Extreme perimeter border (outer 16px around edges)
                    if (x <= 16 || x >= w - 16 || y <= 16 || (y >= h - 16 && x > 350))
                    {
                        if (!(x <= 350 && y >= h - 25 && c.R > 80))
                        {
                            cleaned.SetPixel(x, y, bgPurple);
                            continue;
                        }
                    }

                    // 2. The 4 corner triangular zones
                    // Top-Left corner
                    if (x + y < 250)
                    {
                        cleaned.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    // Top-Right corner
                    if ((w - 1 - x) + y < 240)
                    {
                        cleaned.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    // Bottom-Right corner
                    if ((w - 1 - x) + (h - 1 - y) < 260)
                    {
                        cleaned.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    // Bottom-Left corner outside/under the sleeve
                    if (x < 45 && y > h - 70)
                    {
                        cleaned.SetPixel(x, y, bgPurple);
                        continue;
                    }
                    if (x < 15 && y > 750)
                    {
                        cleaned.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    cleaned.SetPixel(x, y, c);
                }
            }

            // Save to frontend assets (1024x1024)
            SaveFittedIcon(cleaned, 1024, out1024, bgPurple);
            Console.WriteLine("Saved: " + out1024);

            // Save Android Mipmaps
            var mipmaps = new Dictionary<string, int>()
            {
                { "mipmap-mdpi", 48 },
                { "mipmap-hdpi", 72 },
                { "mipmap-xhdpi", 96 },
                { "mipmap-xxhdpi", 144 },
                { "mipmap-xxxhdpi", 192 }
            };

            foreach (var kv in mipmaps)
            {
                string dir = System.IO.Path.Combine(mipmapBase, kv.Key);
                if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
                string outPath = System.IO.Path.Combine(dir, "ic_launcher.png");
                SaveFittedIcon(cleaned, kv.Value, outPath, bgPurple);
                Console.WriteLine("Saved: " + outPath + " (" + kv.Value + "x" + kv.Value + ")");
            }

            cleaned.Dispose();
        }
    }

    private static void SaveFittedIcon(Bitmap source, int size, string outPath, Color bgColor)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;

            using (var brush = new SolidBrush(bgColor))
            {
                g.FillRectangle(brush, 0, 0, size, size);
            }

            g.DrawImage(source, new Rectangle(0, 0, size, size), new Rectangle(0, 0, source.Width, source.Height), GraphicsUnit.Pixel);

            bmp.Save(outPath, ImageFormat.Png);
        }
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.Drawing"

$src = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$out1024 = "c:\Users\User\schedly\frontend\assets\app_icon.png"
$mipmapBase = "c:\Users\User\schedly\frontend\android\app\src\main\res"

[IconProcessor]::CleanAndGenerate($src, $out1024, $mipmapBase)
Write-Host "Done!"
