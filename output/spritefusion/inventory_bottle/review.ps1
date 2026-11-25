Add-Type -AssemblyName System.Drawing
# Misura gli output nativi e compone un confronto senza modificare gli asset.
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$data = Get-Content -Raw "$PSScriptRoot/generation.json" | ConvertFrom-Json
$items = @([pscustomobject]@{label='Originale';path='godot/assets/graphics/ep01_cabin/inventory_bottle.png'})
for($i=0;$i -lt $data.files.Count;$i++){$items += [pscustomobject]@{label="V$($i+1)";path=$data.files[$i].path}}
$sheet = [Drawing.Bitmap]::new(1250,990)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(43,47,52))
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [Drawing.Font]::new('Arial',12)
$g.DrawString('Whiskey inventario | sopra: 2x UI | sotto: 6x | riferimento ambiente:', $font,[Drawing.Brushes]::White,12,12)
$reference = [Drawing.Bitmap]::FromFile("$root/godot/assets/graphics/ep01_cabin/bottle.png")
$g.DrawImage($reference,[Drawing.Rectangle]::new(760,8,$reference.Width*3,$reference.Height*3))
$reference.Dispose()
$rows = @()
for($i=0;$i -lt $items.Count;$i++){
  $item=$items[$i];$b=[Drawing.Bitmap]::FromFile("$root/$($item.path)")
  $xmin=$b.Width;$ymin=$b.Height;$xmax=-1;$ymax=-1;$alphas=@{}
  for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){
    $a=$b.GetPixel($x,$y).A;$alphas[[int]$a]=1
    if($a -gt 0){$xmin=[Math]::Min($xmin,$x);$ymin=[Math]::Min($ymin,$y);$xmax=[Math]::Max($xmax,$x);$ymax=[Math]::Max($ymax,$y)}
  }}
  $w=$xmax-$xmin+1;$h=$ymax-$ymin+1
  $rows += [pscustomobject]@{label=$item.label;path=$item.path;canvas=@($b.Width,$b.Height);bounds=@($xmin,$ymin,($xmax+1),($ymax+1));visible=@($w,$h);binary_alpha=(@($alphas.Keys | Where-Object {$_ -ne 0 -and $_ -ne 255}).Count -eq 0);size_compliant=($w -eq 12 -and $h -ge 29 -and $h -le 31)}
  $cx=($i%5)*250;$cy=55+[Math]::Floor($i/5)*455
  $g.DrawString("$($item.label) - ${w}x${h}",$font,[Drawing.Brushes]::White,($cx+10),$cy)
  # I margini dei canvas nativi sono conservati; ogni anteprima usa nearest neighbor.
  $g.DrawImage($b,[Drawing.Rectangle]::new(($cx+75),($cy+28),($b.Width*2),($b.Height*2)))
  $crop=[Drawing.Rectangle]::new($xmin,$ymin,$w,$h)
  $g.DrawImage($b,[Drawing.Rectangle]::new(($cx+[Math]::Floor((250-$w*6)/2)),($cy+145),($w*6),($h*6)),$crop,[Drawing.GraphicsUnit]::Pixel)
  $b.Dispose()
}
$g.Dispose();$font.Dispose()
$sheet.Save("$PSScriptRoot/comparison.png",[Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
$rows | ConvertTo-Json -Depth 6 | Set-Content "$PSScriptRoot/measurements.json" -Encoding utf8
$rows | Select-Object label,@{n='visible';e={$_.visible -join 'x'}},binary_alpha,size_compliant | Format-Table
