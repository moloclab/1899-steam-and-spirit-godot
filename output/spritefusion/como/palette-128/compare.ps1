# Misura i risultati nativi e crea il confronto senza modificarli.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../../..").Path
$manifest = Get-Content -Raw "$PSScriptRoot/downloads.json" | ConvertFrom-Json
$palette = (Get-Content -Raw "$root/godot/palette/1899-base-128.json" | ConvertFrom-Json).colors
$font = New-Object System.Drawing.Font 'Consolas',11
$sheet = New-Object System.Drawing.Bitmap 960,920
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(32,34,37))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawString('1899 / COMO / PALETTE FLESSIBILE 128',$font,[System.Drawing.Brushes]::White,16,12)
# La prima riga contiene i riferimenti alle loro scale dichiarate.
$refs=@(@{file="$PSScriptRoot/source.png";label='Originale GIF / 40x36 / 4x';scale=4},@{file="$root/godot/assets/graphics/ep01_cabin/como.png";label='Precedente / 40x36 / 4x';scale=4},@{file="$root/godot/assets/graphics/characters/churchill/churchill-stand.png";label='Churchill / 1x';scale=1})
for($i=0;$i -lt $refs.Count;$i++) {
    $im=[System.Drawing.Image]::FromFile($refs[$i].file)
    $g.DrawString($refs[$i].label,$font,[System.Drawing.Brushes]::White,($i*320+16),42)
    $g.DrawImage($im,($i*320+32),68,($im.Width*$refs[$i].scale),($im.Height*$refs[$i].scale))
    $im.Dispose()
}
$validation=@()
for($i=0;$i -lt $manifest.Count;$i++) {
    $item=$manifest[$i]
    $im=[System.Drawing.Bitmap]::FromFile((Join-Path $root $item.file))
    $minX=$im.Width;$minY=$im.Height;$maxX=-1;$maxY=-1
    $alpha=New-Object 'System.Collections.Generic.HashSet[int]'
    $colors=New-Object 'System.Collections.Generic.HashSet[string]'
    $pixelCount=0;$palettePixels=0
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $c=$im.GetPixel($x,$y);[void]$alpha.Add([int]$c.A)
        if($c.A -eq 0){continue}
        $minX=[Math]::Min($minX,$x);$maxX=[Math]::Max($maxX,$x);$minY=[Math]::Min($minY,$y);$maxY=[Math]::Max($maxY,$y)
        $hex='#{0:X6}' -f ($c.ToArgb() -band 0xffffff);[void]$colors.Add($hex);$pixelCount++
        if($hex -in $palette){$palettePixels++}
    }}
    $w=$maxX-$minX+1;$h=$maxY-$minY+1
    $conforms=($w -ge 38 -and $w -le 42 -and $h -ge 35 -and $h -le 37)
    $validation += [ordered]@{variant=($i+1);asset_id=$item.id;file=$item.file;canvas=@($im.Width,$im.Height);visible_bounds=@($minX,$minY,$w,$h);size_conforms=$conforms;alpha_values=@($alpha|Sort-Object);opaque_colors=$colors.Count;exact_palette_pixel_percent=[Math]::Round(100*$palettePixels/$pixelCount,1);decision='not integrated; awaiting visual choice';outline='see visual review'}
    $cx=($i%3)*320+16;$cy=238+[int][Math]::Floor($i/3)*222
    $label='V{0} / soggetto {1}x{2}' -f ($i+1),$w,$h
    $g.DrawString($label,$font,[System.Drawing.Brushes]::White,$cx,$cy)
    $g.DrawString(('canvas {0}x{1} / 4x' -f $im.Width,$im.Height),$font,[System.Drawing.Brushes]::LightGray,$cx,($cy+18))
    $g.DrawImage($im,($cx+32),($cy+40),($im.Width*4),($im.Height*4))
    # Campione alla risoluzione nativa accanto all'ingrandimento.
    $g.DrawImageUnscaled($im,($cx+240),($cy+100))
    $im.Dispose()
}
$g.Dispose();$font.Dispose()
$sheet.Save("$PSScriptRoot/comparison.png",[System.Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
ConvertTo-Json -InputObject $validation -Depth 6 | Set-Content -Encoding UTF8 "$PSScriptRoot/validation.json"
$validation | ForEach-Object { [pscustomobject]@{Variant=$_.variant;Bounds=($_.visible_bounds -join ',');SizeOK=$_.size_conforms;Colors=$_.opaque_colors;Alpha=($_.alpha_values -join ',')} } | Format-Table
