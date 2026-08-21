$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class PerfectNaturalIconBuilder
{
    public static void Build(string srcPath, string outPath)
    {
        using (var src = new Bitmap(srcPath))
        {
            int w = src.Width;
            int h = src.Height;
            Color bgPurple = Color.FromArgb(255, 206, 162, 248);

            var result = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color c = src.GetPixel(x, y);

                    // 1. Clean the outer 16px border perimeter (except where the sleeve exits on the bottom-left)
                    if (x <= 16 || x >= w - 16 || y <= 16 || (y >= h - 16 && x > 350))
                    {
                        if (!(x <= 350 && y >= h - 20 && (c.R > 80 || c.B > 120)))
                        {
                            result.SetPixel(x, y, bgPurple);
                            continue;
                        }
                    }

                    // 2. The 3 corner triangular zones (top-left, top-right, bottom-right)
                    if (x + y < 250 || (w - 1 - x) + y < 240 || (w - 1 - x) + (h - 1 - y) < 260)
                    {
                        result.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    // 3. Extreme bottom-left corner underneath/outside the sleeve
                    if (x < 40 && y > h - 45)
                    {
                        result.SetPixel(x, y, bgPurple);
                        continue;
                    }
                    if (x < 15 && y > 750)
                    {
                        result.SetPixel(x, y, bgPurple);
                        continue;
                    }

                    result.SetPixel(x, y, c);
                }
            }

            // Scale to 1024x1024
            var finalBmp = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(finalBmp))
            {
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                using (var brush = new SolidBrush(bgPurple))
                {
                    g.FillRectangle(brush, 0, 0, 1024, 1024);
                }

                g.DrawImage(result, new Rectangle(0, 0, 1024, 1024), new Rectangle(0, 0, w, h), GraphicsUnit.Pixel);
            }

            finalBmp.Save(outPath, ImageFormat.Png);
            Console.WriteLine("Saved natural pristine icon to: " + outPath);

            result.Dispose();
            finalBmp.Dispose();
        }
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"
$src = "c:\Users\User\schedly\frontend\prototype\app icon2.png"
$preview = "C:\Users\User\.gemini\antigravity-ide\brain\2022d21f-7f4f-418e-b84c-dc148449d45a\app_icon_preview_fix.png"

[PerfectNaturalIconBuilder]::Build($src, $preview)
