# Misura i file nativi e crea confronti statici senza modificare sorgente o scene.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path "$PSScriptRoot/../../../..").Path
$manifest=Get-Content -Raw "$PSScriptRoot/downloads.json" | ConvertFrom-Json
$items=@(@{variant=0;file='output/spritefusion/interphone_tube_full/same-style-128/interphone_tube_full-original.png'})+@($manifest)
$font=[Drawing.Font]::new('Consolas',11)
$sheet=[Drawing.Bitmap]::new(1100,720)
$g=[Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(48,51,55))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawString('Tubo comunicazione / nativo 1x e dettaglio 4x',$font,[Drawing.Brushes]::White,10,8)
$validation=@()
for($i=0;$i -lt $items.Count;$i++){
    $item=$items[$i]
    $im=[Drawing.Bitmap]::new((Join-Path $root $item.file))
    $minX=$im.Width;$minY=$im.Height;$maxX=-1;$maxY=-1
    $alpha=[Collections.Generic.HashSet[int]]::new()
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $c=$im.GetPixel($x,$y);[void]$alpha.Add([int]$c.A)
        if($c.A -eq 0){continue}
        $minX=[Math]::Min($minX,$x);$maxX=[Math]::Max($maxX,$x)
        $minY=[Math]::Min($minY,$y);$maxY=[Math]::Max($maxY,$y)
    }}
    $w=$maxX-$minX+1;$h=$maxY-$minY+1
    $validation+=@{variant=$item.variant;file=$item.file;canvas=@($im.Width,$im.Height);bounds=@($minX,$minY,$w,$h);alpha=@($alpha|Sort-Object);size_conforms=($w -ge 23 -and $w -le 25 -and $h -ge 114 -and $h -le 126)}
    $x=$i*220+8
    $label="V$i";if($i -eq 0){$label='Originale'}
    $g.DrawString($label,$font,[Drawing.Brushes]::White,$x,38)
    $g.DrawString("Soggetto ${w}x${h}",$font,[Drawing.Brushes]::White,$x,58)
    $g.DrawString(('Canvas {0}x{1}' -f $im.Width,$im.Height),$font,[Drawing.Brushes]::LightGray,$x,78)
    # L'anteprima mostra il soggetto dai bounds, lasciando intatto il file nativo.
    $dest=[Drawing.Rectangle]::new(($x+12),110,($w*4),($h*4))
    $g.DrawImage($im,$dest,$minX,$minY,$w,$h,[Drawing.GraphicsUnit]::Pixel)
    $g.DrawImageUnscaled($im,($x+100),580)
    $im.Dispose()
}
$g.Dispose();$sheet.Save("$PSScriptRoot/comparison.png");$sheet.Dispose()
ConvertTo-Json -InputObject $validation -Depth 5 | Set-Content -Encoding UTF8 "$PSScriptRoot/validation.json"
# Confronto sul fondale alle coordinate della scena; e' una simulazione, non una cattura Godot.
$context=[Drawing.Bitmap]::new(1100,500)
$g=[Drawing.Graphics]::FromImage($context);$g.Clear([Drawing.Color]::FromArgb(48,51,55))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawString('Contesto statico / 3x / ancoraggio superiore y=0 / nessuna integrazione',$font,[Drawing.Brushes]::White,8,8)
for($i=0;$i -lt $items.Count;$i++){
    $tile=[Drawing.Bitmap]::new(72,140);$tg=[Drawing.Graphics]::FromImage($tile)
    $bg=[Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/cabin_background.png")
    $tg.DrawImageUnscaled($bg,-454,0);$bg.Dispose()
    $im=[Drawing.Image]::FromFile((Join-Path $root $items[$i].file));$b=$validation[$i].bounds
    $dest=[Drawing.Rectangle]::new(24,0,$b[2],$b[3])
    $tg.DrawImage($im,$dest,$b[0],$b[1],$b[2],$b[3],[Drawing.GraphicsUnit]::Pixel)
    $im.Dispose();$tg.Dispose()
    $label="V$i";if($i -eq 0){$label='Originale'}
    $g.DrawString($label,$font,[Drawing.Brushes]::White,($i*220+8),40)
    $g.DrawImage($tile,($i*220),66,216,420);$tile.Dispose()
}
$g.Dispose();$context.Save("$PSScriptRoot/context.png");$context.Dispose();$font.Dispose()
$validation | ConvertTo-Json -Depth 4
