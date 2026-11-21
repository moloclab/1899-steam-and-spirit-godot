# Misure e confronti statici dei file nativi: non modifica gli asset.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path "$PSScriptRoot/../../../..").Path
$manifest=Get-Content -Raw "$PSScriptRoot/downloads.json" | ConvertFrom-Json
$font=New-Object System.Drawing.Font 'Consolas',11
$sheet=New-Object System.Drawing.Bitmap 960,1240
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(32,34,37))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawString('1899 / LAVABO / STESSO SET DEL COMO',$font,[System.Drawing.Brushes]::White,16,12)
$refs=@(@{file="$PSScriptRoot/sink-original.png";label='Lavabo originale / 40x56 / 4x';scale=4},@{file="$root/godot/assets/graphics/ep01_cabin/como.png";label='Como del set / 40x37 / 4x';scale=4},@{file="$root/godot/assets/graphics/characters/churchill/churchill-stand.png";label='Churchill / 1x';scale=1})
for($i=0;$i -lt $refs.Count;$i++) {
    $im=[System.Drawing.Image]::FromFile($refs[$i].file)
    $g.DrawString($refs[$i].label,$font,[System.Drawing.Brushes]::White,($i*320+8),42)
    $g.DrawImage($im,($i*320+32),68,($im.Width*$refs[$i].scale),($im.Height*$refs[$i].scale));$im.Dispose()
}
$validation=@()
for($i=0;$i -lt $manifest.Count;$i++) {
    $item=$manifest[$i];$im=[System.Drawing.Bitmap]::FromFile((Join-Path $root $item.file))
    $minX=$im.Width;$minY=$im.Height;$maxX=-1;$maxY=-1
    $alpha=New-Object 'System.Collections.Generic.HashSet[int]'
    $colors=New-Object 'System.Collections.Generic.HashSet[int]'
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $c=$im.GetPixel($x,$y);[void]$alpha.Add([int]$c.A);if($c.A -eq 0){continue}
        $minX=[Math]::Min($minX,$x);$maxX=[Math]::Max($maxX,$x);$minY=[Math]::Min($minY,$y);$maxY=[Math]::Max($maxY,$y);[void]$colors.Add($c.ToArgb())
    }}
    $w=$maxX-$minX+1;$h=$maxY-$minY+1
    $validation += [ordered]@{variant=($i+1);asset_id=$item.id;file=$item.file;canvas=@($im.Width,$im.Height);visible_bounds=@($minX,$minY,$w,$h);size_conforms=($w -ge 38 -and $w -le 42 -and $h -ge 54 -and $h -le 58);alpha_values=@($alpha|Sort-Object);opaque_colors=$colors.Count;decision='not integrated; awaiting visual choice';outline='see review.md'}
    $cx=($i%3)*320+8;$cy=316+[int][Math]::Floor($i/3)*302
    $g.DrawString(('V{0} / soggetto {1}x{2}' -f ($i+1),$w,$h),$font,[System.Drawing.Brushes]::White,$cx,$cy)
    $g.DrawString(('canvas {0}x{1} / 4x' -f $im.Width,$im.Height),$font,[System.Drawing.Brushes]::LightGray,$cx,($cy+18))
    $g.DrawImage($im,($cx+4),($cy+40),($im.Width*4),($im.Height*4))
    $g.DrawImageUnscaled($im,($cx+248),($cy+130));$im.Dispose()
}
$g.Dispose();$sheet.Save("$PSScriptRoot/comparison.png");$sheet.Dispose()
ConvertTo-Json -InputObject $validation -Depth 6 | Set-Content -Encoding UTF8 "$PSScriptRoot/validation.json"
# Anteprima sul fondale: comò e calamaio mantengono le coordinate della scena.
$context=New-Object System.Drawing.Bitmap 1400,560
$g=[System.Drawing.Graphics]::FromImage($context);$g.Clear([System.Drawing.Color]::FromArgb(32,34,37))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor;$g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawString('Contesto statico / stesso set / 2x / non e una cattura Godot',$font,[System.Drawing.Brushes]::White,12,10)
for($i=0;$i -lt ($manifest.Count+1);$i++) {
    $tile=New-Object System.Drawing.Bitmap 136,112;$tg=[System.Drawing.Graphics]::FromImage($tile)
    $bg=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/cabin_background.png");$tg.DrawImageUnscaled($bg,-200,-104);$bg.Dispose()
    $como=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/como.png");$tg.DrawImageUnscaled($como,24,59);$como.Dispose()
    $quill=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/feather.png");$tg.DrawImageUnscaled($quill,32,32);$quill.Dispose()
    if($i -eq 0){$path="$PSScriptRoot/sink-original.png";$bounds=@(0,0,40,56);$label='Originale'}
    else{$v=$validation[$i-1];$path=Join-Path $root $v.file;$bounds=$v.visible_bounds;$label="V$i"}
    $im=[System.Drawing.Image]::FromFile($path)
    # Appoggio alla base originale y=200 senza riscalare i pixel visibili.
    $dest=New-Object System.Drawing.Rectangle 72,(96-$bounds[3]),$bounds[2],$bounds[3]
    $tg.DrawImage($im,$dest,$bounds[0],$bounds[1],$bounds[2],$bounds[3],[System.Drawing.GraphicsUnit]::Pixel)
    $im.Dispose();$tg.Dispose();$x=($i%5)*280;$y=40+[int][Math]::Floor($i/5)*260
    $g.DrawString($label,$font,[System.Drawing.Brushes]::White,($x+4),$y);$g.DrawImage($tile,$x,($y+20),272,224);$tile.Dispose()
}
$g.Dispose();$font.Dispose();$context.Save("$PSScriptRoot/context.png");$context.Dispose()
$validation | ForEach-Object { [pscustomobject]@{Variant=$_.variant;Bounds=($_.visible_bounds -join ',');SizeOK=$_.size_conforms;Colors=$_.opaque_colors;Alpha=($_.alpha_values -join ',')} } | Format-Table
