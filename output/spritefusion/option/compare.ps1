# Misura gli sprite nativi e costruisce anteprime su canvas inventario 50x50 senza modificare gli asset.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$assetDir = Join-Path $PSScriptRoot '../../../godot/assets/graphics/ui'
$files = @((Join-Path $PSScriptRoot 'original.png')) + @(1..9 | ForEach-Object {
    $name = if ($_ -eq 1) { 'option-redesign.png' } else { "option-redesign-$_.png" }
    Join-Path $assetDir $name
})
$sheet = [System.Drawing.Bitmap]::new(1500, 1060)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(48,48,48))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [System.Drawing.Font]::new('Arial', 11)
$small = [System.Drawing.Font]::new('Arial', 9)
$measurements = @()
for ($i=0; $i -lt $files.Count; $i++) {
    $b = [System.Drawing.Bitmap]::FromFile($files[$i])
    $minX=$b.Width; $minY=$b.Height; $maxX=-1; $maxY=-1; $alphas=@{}
    for ($y=0; $y -lt $b.Height; $y++) { for ($x=0; $x -lt $b.Width; $x++) {
        $a=$b.GetPixel($x,$y).A; $alphas[[int]$a]=1
        if ($a -gt 0) { $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y); $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y) }
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $measurements += [pscustomobject]@{File=[IO.Path]::GetFileName($files[$i]); CanvasWidth=$b.Width; CanvasHeight=$b.Height; X=$minX; Y=$minY; VisibleWidth=$w; VisibleHeight=$h; Alpha=@($alphas.Keys); SizeConforming=($w -ge 30 -and $w -le 32 -and $h -ge 32 -and $h -le 34)}
    $left=($i%5)*300; $top=[Math]::Floor($i/5)*450
    $label=if($i -eq 0){'Originale'}else{"V$i"}
    $title=if($i -eq 0){'Originale - sagoma circa 31x33'}else{"$label - soggetto ${w}x${h}"}
    $canvasLabel=if($i -eq 0){'Canvas 40x40 opaco, sfondo incluso'}else{"Canvas nativo $($b.Width)x$($b.Height)"}
    $g.DrawString($title,$font,[System.Drawing.Brushes]::White,$left+10,$top+8)
    $g.DrawString($canvasLabel,$small,[System.Drawing.Brushes]::LightGray,$left+10,$top+30)
    if($w -le 50 -and $h -le 50) {
        $g.DrawString('Anteprima inventario 50x50 a scala 2x',$small,[System.Drawing.Brushes]::LightGray,$left+10,$top+47)
        $g.FillRectangle([System.Drawing.Brushes]::Black,$left+100,$top+65,100,100)
        $previewX=$left+100+[int][Math]::Floor((50-$w)/2)*2
        $previewY=$top+65+[int][Math]::Floor((50-$h)/2)*2
        $dest=[System.Drawing.Rectangle]::new($previewX,$previewY,$w*2,$h*2)
        $g.DrawImage($b,$dest,$minX,$minY,$w,$h,[System.Drawing.GraphicsUnit]::Pixel)
    } else {
        # Gli output troppo grandi si mostrano nativi, senza forzarli nel canvas dell'inventario.
        $g.DrawString('NON ENTRA nel 50x50 - nativo a scala 2x',$small,[System.Drawing.Brushes]::LightSalmon,$left+10,$top+47)
        $g.FillRectangle([System.Drawing.Brushes]::Black,$left+102,$top+60,96,96)
        $dest=[System.Drawing.Rectangle]::new($left+102,$top+60,$b.Width*2,$b.Height*2)
        $g.DrawImage($b,$dest,0,0,$b.Width,$b.Height,[System.Drawing.GraphicsUnit]::Pixel)
    }
    $g.DrawString('Dettaglio nearest-neighbor 5x',$small,[System.Drawing.Brushes]::LightGray,$left+10,$top+172)
    $dest=[System.Drawing.Rectangle]::new($left+[int]((300-$w*5)/2),$top+195,$w*5,$h*5)
    $g.DrawImage($b,$dest,$minX,$minY,$w,$h,[System.Drawing.GraphicsUnit]::Pixel)
    $b.Dispose()
}
# I riferimenti restano separati dai candidati e mostrano lo stile approvato per bordo e materiali.
$g.DrawString('Riferimenti approvati: Churchill (1x) e magnete inventario (2x). Anteprime, non screenshot del gioco.',$small,[System.Drawing.Brushes]::White,10,915)
$referencePaths=@('../../../godot/assets/graphics/characters/churchill/churchill-stand.png','../../../godot/assets/graphics/ep01_cabin/inventory_magnet.png')
for($j=0;$j -lt $referencePaths.Count;$j++) {
    $ref=[System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot $referencePaths[$j]))
    $scale=if($j -eq 0){1}else{2}
    $dest=[System.Drawing.Rectangle]::new(20+$j*180,945,$ref.Width*$scale,$ref.Height*$scale)
    $g.DrawImage($ref,$dest,0,0,$ref.Width,$ref.Height,[System.Drawing.GraphicsUnit]::Pixel)
    $ref.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$measurements | Select-Object File,VisibleWidth,VisibleHeight,SizeConforming | Format-Table -AutoSize
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $small.Dispose()

