# Misura gli output nativi e crea solo anteprime nearest-neighbor, senza alterare gli asset.
Add-Type -AssemblyName System.Drawing
$assetDir = Join-Path $PSScriptRoot '../../../godot/assets/graphics/ep01_cabin'
$names = @('inventory_magnet.png') + @(1..9 | ForEach-Object { if ($_ -eq 1) { 'inventory_magnet-redesign.png' } else { "inventory_magnet-redesign-$_.png" } })
$sheet = [System.Drawing.Bitmap]::new(1100, 780)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(48,48,48))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [System.Drawing.Font]::new('Arial', 11)
$small = [System.Drawing.Font]::new('Arial', 9)
$rows = @()
for ($i=0; $i -lt $names.Count; $i++) {
    $b = [System.Drawing.Bitmap]::FromFile((Join-Path $assetDir $names[$i]))
    $minX=$b.Width; $minY=$b.Height; $maxX=-1; $maxY=-1; $alphas=@{}
    for ($y=0; $y -lt $b.Height; $y++) { for ($x=0; $x -lt $b.Width; $x++) {
        $a=$b.GetPixel($x,$y).A; $alphas[[int]$a]=1
        if ($a -gt 0) { $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y); $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y) }
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $rows += [pscustomobject]@{File=$names[$i]; CanvasWidth=$b.Width; CanvasHeight=$b.Height; X=$minX; Y=$minY; VisibleWidth=$w; VisibleHeight=$h; Alpha=@($alphas.Keys); SizeConforming=($w -eq 15 -and $h -eq 15)}
    $left=($i%5)*220; $top=[Math]::Floor($i/5)*300
    $label=if($i -eq 0){'Originale'}else{"V$i"}
    $g.DrawString("$label - soggetto ${w}x${h}",$font,[System.Drawing.Brushes]::White,$left+10,$top+8)
    $g.DrawString("Canvas $($b.Width)x$($b.Height) - vista gioco 2x",$small,[System.Drawing.Brushes]::LightGray,$left+10,$top+30)
    $g.FillRectangle([System.Drawing.Brushes]::Black,$left+10,$top+50,200,100)
    $dest=[System.Drawing.Rectangle]::new($left+[int]((220-$b.Width*2)/2),$top+52,$b.Width*2,$b.Height*2)
    $g.DrawImage($b,$dest,0,0,$b.Width,$b.Height,[System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawString('Dettaglio 8x su grigio',$small,[System.Drawing.Brushes]::LightGray,$left+10,$top+155)
    $dest=[System.Drawing.Rectangle]::new($left+[int]((220-$w*8)/2),$top+178,$w*8,$h*8)
    $g.DrawImage($b,$dest,$minX,$minY,$w,$h,[System.Drawing.GraphicsUnit]::Pixel)
    $b.Dispose()
}
$g.DrawString('Riferimenti di stile approvati: Churchill e calamaio. Anteprime; nessuna integrazione nella scena.',$small,[System.Drawing.Brushes]::White,10,610)
# Mostra i riferimenti approvati nello stesso confronto per valutare dettaglio e bordo.
$referencePaths=@('../../../godot/assets/graphics/characters/churchill/churchill-stand.png','../../../godot/assets/graphics/ep01_cabin/feather.png')
for($j=0;$j -lt $referencePaths.Count;$j++) {
    $ref=[System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot $referencePaths[$j]))
    $scale=if($j -eq 0){1}else{2}
    $dest=[System.Drawing.Rectangle]::new(20+$j*200,640,$ref.Width*$scale,$ref.Height*$scale)
    $g.DrawImage($ref,$dest,0,0,$ref.Width,$ref.Height,[System.Drawing.GraphicsUnit]::Pixel)
    $ref.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$rows | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$rows | Select-Object File,VisibleWidth,VisibleHeight,SizeConforming | Format-Table -AutoSize
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $small.Dispose()
