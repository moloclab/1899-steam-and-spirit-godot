# Confronta le immagini senza modificare i file nativi o la scena.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path "$PSScriptRoot/../../../..").Path
$manifest=Get-Content -Raw "$PSScriptRoot/downloads.json" | ConvertFrom-Json
$items=@(@{label='V4 originale';file='output/spritefusion/interphone_tube_full/narrower/before-37x121.png'},@{label='Riduzione diretta';file='output/spritefusion/interphone_tube_full/edit-half-width/before-integration-19x121.png'})+@($manifest)
$sheet=[Drawing.Bitmap]::new(880,700)
$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(48,51,55))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
$font=[Drawing.Font]::new('Consolas',11)
$measurements=@()
for($i=0;$i -lt $items.Count;$i++){
    $im=[Drawing.Bitmap]::new((Join-Path $root $items[$i].file))
    $minX=$im.Width;$minY=$im.Height;$maxX=-1;$maxY=-1;$alpha=[Collections.Generic.HashSet[int]]::new()
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $c=$im.GetPixel($x,$y);[void]$alpha.Add([int]$c.A);if($c.A -eq 0){continue}
        $minX=[Math]::Min($minX,$x);$maxX=[Math]::Max($maxX,$x);$minY=[Math]::Min($minY,$y);$maxY=[Math]::Max($maxY,$y)
    }}
    $w=$maxX-$minX+1;$h=$maxY-$minY+1;$cx=$i*220+12
    $measurements+=@{label=$items[$i].label;file=$items[$i].file;canvas=@($im.Width,$im.Height);bounds=@($minX,$minY,$w,$h);alpha=@($alpha|Sort-Object)}
    $g.DrawString($items[$i].label,$font,[Drawing.Brushes]::White,$cx,12)
    $g.DrawString("Soggetto ${w}x${h}",$font,[Drawing.Brushes]::White,$cx,32)
    $g.DrawString(('Canvas {0}x{1}' -f $im.Width,$im.Height),$font,[Drawing.Brushes]::LightGray,$cx,52)
    $dest=[Drawing.Rectangle]::new($cx,80,($w*4),($h*4))
    $g.DrawImage($im,$dest,$minX,$minY,$w,$h,[Drawing.GraphicsUnit]::Pixel)
    $g.DrawImageUnscaled($im,$cx,570);$im.Dispose()
}
$g.Dispose();$font.Dispose();$sheet.Save("$PSScriptRoot/comparison.png");$sheet.Dispose()
ConvertTo-Json -InputObject $measurements -Depth 5 | Set-Content -Encoding UTF8 "$PSScriptRoot/validation.json"
$measurements | ConvertTo-Json -Depth 5
