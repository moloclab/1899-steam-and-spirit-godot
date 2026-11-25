Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$assets = Join-Path $root 'godot/assets/graphics/ep01_cabin'
# Include the approved inputs and all native variants without changing their pixels.
$files = @('inventory_feather.png','inventory_magnet.png','inventory_magnet_feather.png')
$files += @(Get-ChildItem "$assets/inventory_magnet_feather-redesign*.png" | Sort-Object Name | ForEach-Object Name)
$sheet = New-Object System.Drawing.Bitmap 960,960
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(35,38,43))
$font = New-Object System.Drawing.Font 'Arial',11
$measurements = @()
for ($i=0; $i -lt $files.Count; $i++) {
    $name=$files[$i]
    $b=[System.Drawing.Bitmap]::FromFile((Join-Path $assets $name))
    $minX=$b.Width; $minY=$b.Height; $maxX=-1; $maxY=-1; $alpha=@{}
    for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){
        $a=$b.GetPixel($x,$y).A; $alpha[[int]$a]=$true
        if($a -gt 0){$minX=[Math]::Min($minX,$x);$minY=[Math]::Min($minY,$y);$maxX=[Math]::Max($maxX,$x);$maxY=[Math]::Max($maxY,$y)}
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $measurements += [pscustomobject]@{file=$name;canvas=@($b.Width,$b.Height);bounds=@($minX,$minY,$w,$h);alphaValues=@($alpha.Keys | Sort-Object)}
    $cx=($i%4)*240; $cy=[Math]::Floor($i/4)*320
    $label=if($i -lt 3){@('Penna','Magnete','Combinato originale')[$i]}else{"V$($i-2)"}
    $g.DrawString("$label - ${w}x${h}",$font,[System.Drawing.Brushes]::White,[single]($cx+10),[single]($cy+8))
    # Show both native scale and an exact nearest-neighbor enlargement.
    $g.DrawImageUnscaled($b,($cx+95),($cy+35))
    for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){
        $c=$b.GetPixel($x,$y)
        if($c.A -gt 0){$brush=New-Object System.Drawing.SolidBrush $c;$g.FillRectangle($brush,($cx+20+$x*4),($cy+105+$y*4),4,4);$brush.Dispose()}
    }}
    $b.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$g.Dispose();$sheet.Dispose();$font.Dispose()
$measurements | ForEach-Object { "$($_.file): $($_.bounds[2])x$($_.bounds[3]); alpha=$($_.alphaValues -join ',')" }
