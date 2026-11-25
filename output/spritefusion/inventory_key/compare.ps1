Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$assets = Join-Path $root 'godot/assets/graphics/ep01_cabin'
# Confronta i file nativi senza modificarne i pixel o le dimensioni.
$files = @((Join-Path $assets 'inventory_key.png'), (Join-Path $root 'godot/assets/graphics/characters/churchill/churchill-stand.png'), (Join-Path $assets 'feather.png'))
$files += @(Get-ChildItem "$assets/inventory_key-redesign*.png" | Sort-Object Name | ForEach-Object FullName)
$sheet = [System.Drawing.Bitmap]::new(1000,960)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(35,38,43))
$font = [System.Drawing.Font]::new('Arial',11)
$measurements = @()
for ($i=0; $i -lt $files.Count; $i++) {
    $b=[System.Drawing.Bitmap]::FromFile($files[$i])
    $minX=$b.Width; $minY=$b.Height; $maxX=-1; $maxY=-1; $alpha=@{}
    for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){
        $a=$b.GetPixel($x,$y).A; $alpha[[int]$a]=$true
        if($a -gt 0){$minX=[Math]::Min($minX,$x);$minY=[Math]::Min($minY,$y);$maxX=[Math]::Max($maxX,$x);$maxY=[Math]::Max($maxY,$y)}
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $measurements += [pscustomobject]@{file=[IO.Path]::GetFileName($files[$i]);canvas=@($b.Width,$b.Height);bounds=@($minX,$minY,$w,$h);alphaValues=@($alpha.Keys | Sort-Object);sizeConforming=($w -eq 13 -and $h -ge 31 -and $h -le 33)}
    $cx=($i%4)*250; $cy=[Math]::Floor($i/4)*320
    $label=if($i -lt 3){@('Originale','Churchill','Calamaio')[$i]}else{"V$($i-2)"}
    $g.DrawString("$label - ${w}x${h}",$font,[System.Drawing.Brushes]::White,[single]($cx+10),[single]($cy+8))
    $g.DrawImageUnscaled($b,($cx+90),($cy+34))
    # Mostra la chiave centrata a scala inventario 2x, poi ingrandita 4x; i riferimenti a 2x.
    $scale=if($i -eq 1){2}else{4}
    for($y=$minY;$y -le $maxY;$y++){for($x=$minX;$x -le $maxX;$x++){
        $c=$b.GetPixel($x,$y)
        if($c.A -gt 0){
            $brush=[System.Drawing.SolidBrush]::new($c)
            $g.FillRectangle($brush,($cx+20+($x-$minX)*$scale),($cy+105+($y-$minY)*$scale),$scale,$scale)
            if($i -eq 0 -or $i -ge 3){$g.FillRectangle($brush,($cx+135+($x-$minX)*2),($cy+105+($y-$minY)*2),2,2)}
            $brush.Dispose()
        }
    }}
    $b.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$g.Dispose();$sheet.Dispose();$font.Dispose()
$measurements | ConvertTo-Json -Depth 5 -Compress
