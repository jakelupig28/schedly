$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class CenteredIconBuilder
{
    public static void Build(string srcPath, string out1024, string mipmapBase)
    {
        using (var src = new Bitmap(srcPath))
        {
            int w = src.Width;
            int h = src.Height;
            Color bgPurple = Color.FromArgb(255, 206, 162, 248);
            Color sleevePurple = Color.FromArgb(255, 165, 101, 240);
            Color blackStroke = Color.FromArgb(255, 15, 15, 20);

            var cleanMaster = new Bitmap(w, h + 150, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(cleanMaster))
            {
                g.Clear(Color.Transparent);
            }

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    // 1. Filter out squircle frame and corners
                    if (x <= 18 || x >= w - 18 || y <= 18 || y >= h - 18) continue;
                    if (x + y < 250) continue;
                    if ((w - 1 - x) + y < 240) continue;
                    if ((w - 1 - x) + (h - 1 - y) < 260) continue;
                    // Filter entire bottom-left zone below y=850, x<140 so no squircle artifacts survive
                    if (x < 140 && y > 850) continue;

                    Color c = src.GetPixel(x, y);
                    int diff = Math.Abs(c.R - bgPurple.R) + Math.Abs(c.G - bgPurple.G) + Math.Abs(c.B - bgPurple.B);

                    if (diff > 25)
                    {
                        cleanMaster.SetPixel(x, y, c);
                    }
                }
            }

            // Step 2: Draw pristine, perfectly shaped sleeve cuff
            using (var g = Graphics.FromImage(cleanMaster))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                using (var brush = new SolidBrush(sleevePurple))
                using (var pen = new Pen(blackStroke, 12f) { StartCap = LineCap.Round, EndCap = LineCap.Round, LineJoin = LineJoin.Round })
                {
                    Point[] sleevePoly = new Point[]
                    {
                        new Point(105, 870),
                        new Point(15, 1070),
                        new Point(235, 1140),
                        new Point(345, 990),
                    };
                    g.FillPolygon(brush, sleevePoly);
                    g.DrawLine(pen, new Point(105, 870), new Point(15, 1070));
                    g.DrawLine(pen, new Point(15, 1070), new Point(235, 1140));
                    g.DrawLine(pen, new Point(235, 1140), new Point(345, 990));
                }
            }

            // Recompute bounding box
            int minX = cleanMaster.Width, maxX = 0, minY = cleanMaster.Height, maxY = 0;
            for (int y = 0; y < cleanMaster.Height; y++)
            {
                for (int x = 0; x < cleanMaster.Width; x++)
                {
                    Color c = cleanMaster.GetPixel(x, y);
                    if (c.A > 30)
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            int artW = maxX - minX + 1;
            int artH = maxY - minY + 1;

            var cropped = new Bitmap(artW, artH, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(cropped))
            {
                g.DrawImage(cleanMaster, new Rectangle(0, 0, artW, artH), new Rectangle(minX, minY, artW, artH), GraphicsUnit.Pixel);
            }

            // Step 3: Center onto 1024x1024 with 6.5% safe margin
            int canvasSize = 1024;
            int padding = 65;
            int availSize = canvasSize - (padding * 2);

            double scale = Math.Min((double)availSize / artW, (double)availSize / artH);
            int drawW = (int)(artW * scale);
            int drawH = (int)(artH * scale);

            int drawX = (canvasSize - drawW) / 2;
            int drawY = (canvasSize - drawH) / 2;

            var final1024 = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(final1024))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                using (var brush = new SolidBrush(bgPurple))
                {
                    g.FillRectangle(brush, 0, 0, canvasSize, canvasSize);
                }

                g.DrawImage(cropped, new Rectangle(drawX, drawY, drawW, drawH), new Rectangle(0, 0, artW, artH), GraphicsUnit.Pixel);
            }

            final1024.Save(out1024, ImageFormat.Png);
            Console.WriteLine("Saved 1024x1024 master to: " + out1024);

            // Step 4: Generate all Android mipmaps
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
                SaveFittedIcon(final1024, kv.Value, outPath, bgPurple);
                Console.WriteLine("Saved: " + outPath + " (" + kv.Value + "x" + kv.Value + ")");
            }

            cleanMaster.Dispose();
            cropped.Dispose();
            final1024.Dispose();
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

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"
$src = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$out1024 = "c:\Users\User\schedly\frontend\assets\app_icon.png"
$mipmapBase = "c:\Users\User\schedly\frontend\android\app\src\main\res"

[CenteredIconBuilder]::Build($src, $out1024, $mipmapBase)
Write-Host "Done!"
