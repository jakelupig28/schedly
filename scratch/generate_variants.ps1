$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class IconVariants
{
    public static void GenerateBoth(string srcPath, string outNatural, string outBalanced)
    {
        using (var src = new Bitmap(srcPath))
        {
            int w = src.Width;
            int h = src.Height;
            Color bgPurple = Color.FromArgb(255, 206, 162, 248);

            var cleanMaster = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color c = src.GetPixel(x, y);

                    // 1. Extreme perimeter borders
                    if (x <= 16 || x >= w - 16 || y <= 16 || (y >= h - 16 && x > 350))
                    {
                        if (!(x <= 350 && y >= h - 20 && (c.R > 80 || c.B > 120)))
                        {
                            cleanMaster.SetPixel(x, y, bgPurple);
                            continue;
                        }
                    }

                    // 2. Corner triangular zones
                    if (x + y < 250 || (w - 1 - x) + y < 240 || (w - 1 - x) + (h - 1 - y) < 260)
                    {
                        cleanMaster.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    // 3. Extreme bottom-left corner underneath sleeve
                    if (x < 40 && y > h - 45)
                    {
                        cleanMaster.SetPixel(x, y, bgPurple);
                        continue;
                    }
                    if (x < 15 && y > 750)
                    {
                        cleanMaster.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    cleanMaster.SetPixel(x, y, c);
                }
            }

            // Variant 1: Natural Full-Bleed (Original 1:1 Scale & Flow)
            var bmpNatural = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(bmpNatural))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                using (var brush = new SolidBrush(bgPurple))
                {
                    g.FillRectangle(brush, 0, 0, 1024, 1024);
                }
                g.DrawImage(cleanMaster, new Rectangle(0, 0, 1024, 1024), new Rectangle(0, 0, w, h), GraphicsUnit.Pixel);
            }
            bmpNatural.Save(outNatural, ImageFormat.Png);

            // Variant 2: Subtle Upward Balance (Shifted 40px up & 20px right with continuous natural arm extension)
            var bmpBalanced = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(bmpBalanced))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                using (var brush = new SolidBrush(bgPurple))
                {
                    g.FillRectangle(brush, 0, 0, 1024, 1024);
                }

                // Draw shifted artwork
                g.DrawImage(cleanMaster, new Rectangle(18, -35, 1024, 1024), new Rectangle(0, 0, w, h), GraphicsUnit.Pixel);

                // Fill continuous arm sleeve down to bottom-left corner seamlessly
                Color sleevePurple = Color.FromArgb(255, 165, 101, 240);
                Color blackStroke = Color.FromArgb(255, 15, 15, 20);
                using (var brush = new SolidBrush(sleevePurple))
                using (var pen = new Pen(blackStroke, 8f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
                {
                    Point[] armPoly = new Point[]
                    {
                        new Point(0, 750),
                        new Point(0, 1024),
                        new Point(370, 1024),
                        new Point(300, 950),
                        new Point(80, 800)
                    };
                    g.FillPolygon(brush, armPoly);
                    g.DrawLine(pen, new Point(0, 770), new Point(0, 1024));
                    g.DrawLine(pen, new Point(300, 950), new Point(370, 1024));
                }
            }
            bmpBalanced.Save(outBalanced, ImageFormat.Png);

            cleanMaster.Dispose();
            bmpNatural.Dispose();
            bmpBalanced.Dispose();
        }
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"
$src = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$v1 = "C:\Users\User\.gemini\antigravity-ide\brain\2022d21f-7f4f-418e-b84c-dc148449d45a\app_icon_v1_natural.png"
$v2 = "C:\Users\User\.gemini\antigravity-ide\brain\2022d21f-7f4f-418e-b84c-dc148449d45a\app_icon_v2_balanced.png"

[IconVariants]::GenerateBoth($src, $v1, $v2)
Write-Host "Generated both previews!"
