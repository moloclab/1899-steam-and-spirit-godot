# Riduce solo la larghezza con campionamento nearest neighbor, senza nuovi colori o sfocature.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path "$PSScriptRoot/../../../..").Path
$target=Join-Path $root 'godot/assets/graphics/ep01_cabin/interphone_tube_full.png'
$backup=Join-Path $PSScriptRoot 'before-37x121.png'
# Riparte sempre dalla V4 originale per evitare riduzioni cumulative.
if(-not (Test-Path -LiteralPath $backup)){Copy-Item -LiteralPath $target -Destination $backup}
$source=[Drawing.Bitmap]::new($backup)
$result=[Drawing.Bitmap]::new(19,$source.Height)
for($y=0;$y -lt $source.Height;$y++){
    for($x=0;$x -lt 19;$x++){
        # Campiona il centro di ogni colonna finale mantenendo invariata la coordinata verticale.
        $sourceX=[Math]::Min($source.Width-1,[int][Math]::Floor(($x+0.5)*$source.Width/19))
        $result.SetPixel($x,$y,$source.GetPixel($sourceX,$y))
    }
}
$result.Save($target,[Drawing.Imaging.ImageFormat]::Png)
$sheet=[Drawing.Bitmap]::new(440,550)
$g=[Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(48,51,55))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
$font=[Drawing.Font]::new('Consolas',12)
$g.DrawString('Prima: 37x121',$font,[Drawing.Brushes]::White,12,12)
$g.DrawString('Dopo: 19x121',$font,[Drawing.Brushes]::White,232,12)
$g.DrawImage($source,24,48,148,484)
$g.DrawImage($result,244,48,76,484)
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'))
$sheet.Dispose();$source.Dispose();$result.Dispose()
