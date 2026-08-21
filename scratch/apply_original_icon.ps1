$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class OriginalIconApplier
{
    public static void Apply(string srcPath, string out1024, string mipmapBase)
    {
        using (var src = new Bitmap(srcPath))
        {
            // 1. Save 1024x1024 master
            SaveResized(src, 1024, out1024);
            Console.WriteLine("Saved 1024x1024: " + out1024);

            // 2. Android Mipmaps
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
                SaveResized(src, kv.Value, outPath);
                Console.WriteLine("Saved: " + outPath + " (" + kv.Value + "x" + kv.Value + ")");
            }
        }
    }

    private static void SaveResized(Bitmap source, int size, string outPath)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;

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

[OriginalIconApplier]::Apply($src, $out1024, $mipmapBase)
Write-Host "Original app icon2.png applied to assets and all mipmaps!"
