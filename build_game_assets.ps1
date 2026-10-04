$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.IO;

public class AssetBuilder {
    public static void CropAndSaveTransparent(string inputPath, string outputPath, int cropX, int cropY, int cropW, int cropH, bool removeBlack, bool removeWhite, int tolerance, int targetMaxW = 0, int targetMaxH = 0) {
        using (Bitmap src = new Bitmap(inputPath)) {
            if (cropW <= 0) cropW = src.Width - cropX;
            if (cropH <= 0) cropH = src.Height - cropY;
            Rectangle rect = new Rectangle(cropX, cropY, cropW, cropH);

            using (Bitmap cropped = src.Clone(rect, PixelFormat.Format32bppArgb)) {
                BitmapData data = cropped.LockBits(new Rectangle(0, 0, cropped.Width, cropped.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int bytes = Math.Abs(data.Stride) * cropped.Height;
                byte[] rgb = new byte[bytes];
                Marshal.Copy(data.Scan0, rgb, 0, bytes);

                int height = cropped.Height;
                int width = cropped.Width;
                int stride = data.Stride;

                for (int y = 0; y < height; y++) {
                    int rowOffset = y * stride;
                    for (int x = 0; x < width; x++) {
                        int idx = rowOffset + (x * 4);
                        byte b = rgb[idx + 0];
                        byte g = rgb[idx + 1];
                        byte r = rgb[idx + 2];
                        byte a = rgb[idx + 3];

                        if (removeBlack) {
                            if (r <= tolerance && g <= tolerance && b <= tolerance) {
                                rgb[idx + 3] = 0;
                            }
                        }
                        if (removeWhite) {
                            if (r >= (255 - tolerance) && g >= (255 - tolerance) && b >= (255 - tolerance)) {
                                rgb[idx + 3] = 0;
                            }
                        }
                    }
                }

                Marshal.Copy(rgb, 0, data.Scan0, bytes);
                cropped.UnlockBits(data);

                // Optional resize if target size given
                if (targetMaxW > 0 && (cropped.Width > targetMaxW || cropped.Height > targetMaxH)) {
                    float ratio = Math.Min((float)targetMaxW / cropped.Width, (float)targetMaxH / cropped.Height);
                    int nw = (int)(cropped.Width * ratio);
                    int nh = (int)(cropped.Height * ratio);
                    using (Bitmap scaled = new Bitmap(nw, nh, PixelFormat.Format32bppArgb)) {
                        using (Graphics g = Graphics.FromImage(scaled)) {
                            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                            g.DrawImage(cropped, 0, 0, nw, nh);
                        }
                        scaled.Save(outputPath, ImageFormat.Png);
                    }
                } else {
                    cropped.Save(outputPath, ImageFormat.Png);
                }
            }
        }
        Console.WriteLine("Saved: " + outputPath);
    }

    public static void ResizeImage(string inputPath, string outputPath, int newW, int newH) {
        using (Bitmap src = new Bitmap(inputPath)) {
            using (Bitmap dest = new Bitmap(newW, newH, PixelFormat.Format32bppArgb)) {
                using (Graphics g = Graphics.FromImage(dest)) {
                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.DrawImage(src, 0, 0, newW, newH);
                }
                dest.Save(outputPath, ImageFormat.Png);
            }
        }
        Console.WriteLine("Resized to " + newW + "x" + newH + ": " + outputPath);
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'AssetBuilder').Type) {
    Add-Type -TypeDefinition $csharp -ReferencedAssemblies System.Drawing
}

$assetsDir = Join-Path (Get-Location) "assets"
if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}

Write-Host "Extracting assets..."

# 1. Dino (tight crop from dianous.png: x=309, y=155, w=938, h=819 -> resize to max 400x350)
[AssetBuilder]::CropAndSaveTransparent("dianous.png", "assets\dino.png", 309, 155, 938, 819, $false, $false, 0, 420, 360)

# 2. Dino head (for loading bar / badges: x=850, y=155, w=390, h=350)
[AssetBuilder]::CropAndSaveTransparent("dianous.png", "assets\dino_head.png", 850, 155, 397, 340, $false, $false, 0, 120, 120)

# 3. Meat (x=121, y=69, w=520, h=629)
[AssetBuilder]::CropAndSaveTransparent("meat.jpeg", "assets\meat.png", 121, 69, 520, 629, $false, $true, 25, 120, 120)

# 4. Rocks from main icons.jpeg (clean without divider lines)
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock1.png", 393, 5, 59, 51, $true, $false, 25, 160, 140)
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock2.png", 493, 9, 54, 52, $true, $false, 25, 160, 140)
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock3.png", 340, 57, 48, 67, $true, $false, 25, 150, 180)
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock4.png", 391, 60, 56, 64, $true, $false, 25, 150, 170)
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock5.png", 454, 75, 70, 62, $true, $false, 25, 170, 150)

# 5. Fireball projectile from main icons.jpeg: x=165, y=462, w=172, h=69
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\fireball.png", 163, 460, 176, 73, $true, $false, 20, 180, 80)

# 6. Exploding rock debris from main icons.jpeg: x=635, y=479, w=90, h=76
[AssetBuilder]::CropAndSaveTransparent("main icons.jpeg", "assets\rock_debris.png", 633, 477, 94, 80, $true, $false, 20, 120, 100)

# 7. Gauge icons from icons.jpeg
[AssetBuilder]::CropAndSaveTransparent("icons.jpeg", "assets\icon_fire.png", 151, 283, 202, 202, $true, $false, 20, 120, 120)
[AssetBuilder]::CropAndSaveTransparent("icons.jpeg", "assets\icon_strength.png", 396, 283, 187, 202, $true, $false, 20, 120, 120)
[AssetBuilder]::CropAndSaveTransparent("icons.jpeg", "assets\icon_strength_glow.png", 619, 266, 238, 238, $true, $false, 20, 140, 140)

# 8. Loading screen background (downsampled 8000x4500 to 1920x1080)
[AssetBuilder]::ResizeImage("LOADING SCREEN.png", "assets\loading_screen.png", 1920, 1080)

# 9. Title logo from LOADING SCREEN.png (approx top center)
[AssetBuilder]::CropAndSaveTransparent("assets\loading_screen.png", "assets\title_logo.png", 280, 270, 1360, 260, $false, $false, 0, 800, 160)

Write-Host "All assets prepared!"
