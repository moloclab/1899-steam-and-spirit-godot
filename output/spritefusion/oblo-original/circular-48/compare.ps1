# Crea un confronto nearest-neighbor e misura gli asset senza alterare i PNG nativi.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$paths = @((Join-Path $root 'frame-0-original.png'))
for ($i=1; $i -le 9; $i++) {
    $suffix = if ($i -eq 1) { '' } else { '-'+$i }
    $paths += Join-Path $root ('oblo-original-redesign'+$suffix+'.png')
}
$canvas = [Drawing.Bitmap]::new(1200,700)
$g = [Drawing.Graphics]::FromImage($canvas)
$g.Clear([Drawing.Color]::FromArgb(55,55,59))
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [Drawing.Font]::new('Arial',12)
$metrics = @()
for ($i=0; $i -lt $paths.Count; $i++) {
    $im = [Drawing.Bitmap]::FromFile($paths[$i])
    $minX=$im.Width; $minY=$im.Height; $maxX=-1; $maxY=-1
    $alpha = [Collections.Generic.HashSet[int]]::new()
    for($y=0;$y -lt $im.Height;$y++) { for($x=0;$x -lt $im.Width;$x++) {
        $a=$im.GetPixel($x,$y).A
        [void]$alpha.Add([int]$a)
        if($a -gt 0) { $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y); $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y) }
    } }
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $label=if($i -eq 0){'Originale'}else{'Variante '+$i}
    $metrics += [pscustomobject]@{label=$label;file=[IO.Path]::GetFileName($paths[$i]);canvas=@($im.Width,$im.Height);bounds=@($minX,$minY,($maxX+1),($maxY+1));visible=@($w,$h);alpha=@($alpha);size_ok=($w -ge 46 -and $w -le 50 -and $h -ge 46 -and $h -le 50)}
    $cx=($i%5)*240; $cy=[Math]::Floor($i/5)*280
    $g.DrawString($label,$font,[Drawing.Brushes]::White,$cx+16,$cy+8)
    $g.DrawImage($im,[Drawing.Rectangle]::new($cx+24,$cy+34,192,192),0,0,$im.Width,$im.Height,[Drawing.GraphicsUnit]::Pixel)
    $g.DrawString(('Visibile: '+$w+' x '+$h),$font,[Drawing.Brushes]::White,$cx+16,$cy+232)
    $g.DrawImage($im,[Drawing.Rectangle]::new($cx+180,$cy+227,48,48),0,0,$im.Width,$im.Height,[Drawing.GraphicsUnit]::Pixel)
    $im.Dispose()
}
# Include il riferimento stilistico approvato a risoluzione nativa.
$referencePath = Join-Path $root '../../../../godot/assets/graphics/characters/churchill/churchill-stand.png'
$reference = [Drawing.Bitmap]::FromFile([IO.Path]::GetFullPath($referencePath))
$g.DrawString('Riferimento stile: Churchill approvato (dimensione nativa)', $font, [Drawing.Brushes]::White, 20, 575)
$g.DrawImage($reference,[Drawing.Rectangle]::new(540,575,$reference.Width,$reference.Height),0,0,$reference.Width,$reference.Height,[Drawing.GraphicsUnit]::Pixel)
$reference.Dispose()
$canvas.Save((Join-Path $root 'comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$metrics | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root 'metrics.json')
$metrics | Select-Object label,@{Name='visible';Expression={$_.visible -join 'x'}},size_ok | Format-Table -AutoSize
$font.Dispose(); $g.Dispose(); $canvas.Dispose()

