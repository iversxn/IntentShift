$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$OutputPath = Join-Path $RepositoryRoot 'apps\lua\IntentShift\icon.png'
$Bitmap = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
$Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$Graphics.Clear([System.Drawing.Color]::Transparent)

$Background = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 16, 24, 32))
$Cyan = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 39, 215, 242))
$White = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
$Border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 70, 224, 244), 10)

$Outer = [System.Drawing.Drawing2D.GraphicsPath]::new()
$Outer.AddArc(18, 18, 108, 108, 180, 90)
$Outer.AddArc(130, 18, 108, 108, 270, 90)
$Outer.AddArc(130, 130, 108, 108, 0, 90)
$Outer.AddArc(18, 130, 108, 108, 90, 90)
$Outer.CloseFigure()
$Graphics.FillPath($Background, $Outer)
$Graphics.DrawPath($Border, $Outer)

$Upper = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(57, 92), [System.Drawing.PointF]::new(150, 92),
  [System.Drawing.PointF]::new(125, 67), [System.Drawing.PointF]::new(142, 50),
  [System.Drawing.PointF]::new(197, 104), [System.Drawing.PointF]::new(142, 158),
  [System.Drawing.PointF]::new(125, 141), [System.Drawing.PointF]::new(150, 116),
  [System.Drawing.PointF]::new(57, 116)
)
$Lower = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(199, 176), [System.Drawing.PointF]::new(106, 176),
  [System.Drawing.PointF]::new(131, 201), [System.Drawing.PointF]::new(114, 218),
  [System.Drawing.PointF]::new(59, 164), [System.Drawing.PointF]::new(114, 110),
  [System.Drawing.PointF]::new(131, 127), [System.Drawing.PointF]::new(106, 152),
  [System.Drawing.PointF]::new(199, 152)
)
$Graphics.FillPolygon($Cyan, $Upper)
$Graphics.FillPolygon($White, $Lower)

$Bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$Graphics.Dispose()
$Bitmap.Dispose()
$Background.Dispose()
$Cyan.Dispose()
$White.Dispose()
$Border.Dispose()
$Outer.Dispose()

Write-Output "Rendered: $OutputPath"
