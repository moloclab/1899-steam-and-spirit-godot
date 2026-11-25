Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$sheet = New-Object System.Drawing.Bitmap 780,840
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(35,38,43))
$font = New-Object System.Drawing.Font 'Arial',12
$measurements = @()
for ($i=0; $i -lt 9; $i++) {
    $suffix = if ($i -eq 0) { '' } else { '-' + ($i+1) }
    $file = "godot/assets/graphics/ui/inventory_frame-redesign$suffix.png"
    $b = [System.Drawing.Bitmap]::FromFile((Join-Path $root $file))
    $cx = ($i % 3)*260; $cy = [Math]::Floor($i/3)*280
    $g.DrawString("V$($i+1) - $($b.Width)x$($b.Height)",$font,[System.Drawing.Brushes]::White,[single]($cx+12),[single]($cy+10))
    $g.DrawImageUnscaled($b,($cx+12),($cy+36))
    $alpha=@{}; $minX=$b.Width; $minY=$b.Height; $maxX=-1; $maxY=-1
    # Replica i pixel nel confronto senza modificare le immagini native.
    for ($y=0; $y -lt $b.Height; $y++) { for ($x=0; $x -lt $b.Width; $x++) {
        $c=$b.GetPixel($x,$y); $alpha[[int]$c.A]=$true
        if ($c.A -gt 0) {
            $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y)
            $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y)
            $brush=New-Object System.Drawing.SolidBrush $c
            $g.FillRectangle($brush,($cx+70+$x*3),($cy+105+$y*3),3,3)
            $brush.Dispose()
        }
    }}
    $measurements += [pscustomobject]@{file=$file;canvas=@($b.Width,$b.Height);bounds=@($minX,$minY,($maxX-$minX+1),($maxY-$minY+1));alphaValues=@($alpha.Keys | Sort-Object);centerAlpha=$b.GetPixel(24,24).A}
    $b.Dispose()
}
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$g.Dispose(); $sheet.Dispose(); $font.Dispose()
$measurements | ConvertTo-Json -Depth 5 -Compress
