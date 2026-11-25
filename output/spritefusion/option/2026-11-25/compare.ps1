# Misura i risultati nativi e mostra anteprime senza alterare i pixel degli asset.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$meta = Get-Content (Join-Path $PSScriptRoot 'generation.json') -Raw | ConvertFrom-Json
$files = @((Join-Path $PSScriptRoot 'original.png')) + @($meta.outputs | ForEach-Object { Join-Path $root $_.localFile })
$sheet = [Drawing.Bitmap]::new(1200, 1100)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(40, 42, 44))
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [Drawing.Font]::new('Arial', 11)
$measurements = @()
for ($i=0; $i -lt $files.Count; $i++) {
    $b = [Drawing.Bitmap]::new($files[$i])
    $x0=$b.Width; $y0=$b.Height; $x1=-1; $y1=-1; $alphas=@{}
    for($y=0; $y -lt $b.Height; $y++) { for($x=0; $x -lt $b.Width; $x++) {
        $a=$b.GetPixel($x,$y).A; $alphas[[int]$a]=1
        if($a -gt 0) { $x0=[Math]::Min($x0,$x); $y0=[Math]::Min($y0,$y); $x1=[Math]::Max($x1,$x); $y1=[Math]::Max($y1,$y) }
    }}
    $w=$x1-$x0+1; $h=$y1-$y0+1
    $fits=$w -le 40 -and $h -le 40
    $measurements += [PSCustomObject]@{variant=$i;file=$files[$i];canvas=@($b.Width,$b.Height);bounds=@($x0,$y0,$w,$h);alpha=@($alphas.Keys);fits40=$fits}
    $left=($i%5)*240; $top=[int][Math]::Floor($i/5)*460
    $label=if($i -eq 0){'Originale'}else{"V$i"}
    $g.DrawString("$label - soggetto ${w}x${h}",$font,[Drawing.Brushes]::White,$left+10,$top+10)
    $status=if($fits){'Entra in 40x40'}else{'OLTRE 40x40'}
    $g.DrawString($status,$font,[Drawing.Brushes]::LightGray,$left+10,$top+32)
    # Scala di gioco 2x; si centra soltanto il soggetto che entra nel canvas finale.
    $g.DrawString('Anteprima 2x',$font,[Drawing.Brushes]::LightGray,$left+10,$top+58)
    $g.FillRectangle([Drawing.Brushes]::Black,$left+72,$top+84,96,96)
    $dest=[Drawing.Rectangle]::new($left+72,$top+84,$b.Width*2,$b.Height*2)
    $g.DrawImage($b,$dest,0,0,$b.Width,$b.Height,[Drawing.GraphicsUnit]::Pixel)
    $g.DrawString('Dettaglio 5x',$font,[Drawing.Brushes]::LightGray,$left+10,$top+194)
    $dest=[Drawing.Rectangle]::new($left+[int][Math]::Floor((240-$w*5)/2),$top+224,$w*5,$h*5)
    $g.DrawImage($b,$dest,$x0,$y0,$w,$h,[Drawing.GraphicsUnit]::Pixel)
    $b.Dispose()
}
# I riferimenti approvati permettono di confrontare dettaglio e contorno.
$g.DrawString('Riferimenti: Churchill 1x e magnete 2x. Anteprime, non screenshot della scena.',$font,[Drawing.Brushes]::White,10,940)
$refs=@('godot/assets/graphics/characters/churchill/churchill-stand.png','godot/assets/graphics/ep01_cabin/inventory_magnet.png')
for($j=0;$j -lt $refs.Count;$j++) {
    $b=[Drawing.Bitmap]::new((Join-Path $root $refs[$j])); $s=$j+1
    $dest=[Drawing.Rectangle]::new(20+$j*170,975,$b.Width*$s,$b.Height*$s)
    $g.DrawImage($b,$dest,0,0,$b.Width,$b.Height,[Drawing.GraphicsUnit]::Pixel); $b.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$measurements | Select-Object variant,bounds,alpha,fits40 | Format-Table -AutoSize
$g.Dispose(); $sheet.Dispose(); $font.Dispose()
