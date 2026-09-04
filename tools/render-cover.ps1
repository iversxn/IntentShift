$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$IconPath = Join-Path $RepositoryRoot 'apps\lua\IntentShift\icon.png'
$OutputPath = Join-Path $RepositoryRoot 'assets\intent-shift-cover.png'
$Bitmap = [System.Drawing.Bitmap]::new(1600, 900, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
$Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$Background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
  [System.Drawing.Point]::new(0, 0),
  [System.Drawing.Point]::new(1600, 900),
  [System.Drawing.Color]::FromArgb(255, 8, 15, 23),
  [System.Drawing.Color]::FromArgb(255, 13, 52, 65)
)
$Graphics.FillRectangle($Background, 0, 0, 1600, 900)

$AccentPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 39, 215, 242), 3)
for ($offset = -500; $offset -lt 1800; $offset += 90) {
  $Graphics.DrawLine($AccentPen, $offset, 900, $offset + 700, 0)
}

$Icon = [System.Drawing.Image]::FromFile($IconPath)
$Graphics.DrawImage($Icon, 150, 210, 430, 430)

$TitleFont = [System.Drawing.Font]::new('Segoe UI Semibold', 104, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$TaglineFont = [System.Drawing.Font]::new('Segoe UI', 40, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$ChipFont = [System.Drawing.Font]::new('Segoe UI Semibold', 25, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$White = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$Muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 190, 215, 224))
$Cyan = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 39, 215, 242))
$Chip = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 16, 32, 42))

$Graphics.DrawString('IntentShift', $TitleFont, $White, 680, 255)
$Graphics.DrawString('Adaptive automatic gearbox for Assetto Corsa', $TaglineFont, $Muted, 690, 385)
$Graphics.FillRectangle($Cyan, 690, 465, 590, 8)

$chips = @('CRUISE  ROAD  SPORT', 'NATIVE CSP CONTROLS', 'NO KEY BINDS')
$x = 690
foreach ($label in $chips) {
  $size = $Graphics.MeasureString($label, $ChipFont)
  $width = [int]$size.Width + 46
  $Graphics.FillRectangle($Chip, $x, 525, $width, 62)
  $Graphics.DrawString($label, $ChipFont, $White, $x + 23, 540)
  $x += $width + 18
}

$Graphics.DrawString('by iversxn', $TaglineFont, $Cyan, 695, 650)
$Bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$Background.Dispose()
$AccentPen.Dispose()
$Icon.Dispose()
$TitleFont.Dispose()
$TaglineFont.Dispose()
$ChipFont.Dispose()
$White.Dispose()
$Muted.Dispose()
$Cyan.Dispose()
$Chip.Dispose()
$Graphics.Dispose()
$Bitmap.Dispose()

Write-Output "Rendered: $OutputPath"
