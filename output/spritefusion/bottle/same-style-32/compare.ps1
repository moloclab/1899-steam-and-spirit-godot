Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../../..").Path
$assetDir = Join-Path $root 'godot/assets/graphics/ep01_cabin'

# Measure actual visible bounds without changing any generated image.
function Measure-Sprite($image) {
    $left=$image.Width; $top=$image.Height; $right=-1; $bottom=-1; $alpha=@{}
    for($y=0;$y -lt $image.Height;$y++) {
        for($x=0;$x -lt $image.Width;$x++) {
            $a=$image.GetPixel($x,$y).A; $alpha[[int]$a]=1
            if($a -gt 0) {
                $left=[Math]::Min($left,$x); $top=[Math]::Min($top,$y)
                $right=[Math]::Max($right,$x); $bottom=[Math]::Max($bottom,$y)
            }
        }
    }
    return @{ x=$left; y=$top; width=$right-$left+1; height=$bottom-$top+1; alpha=@($alpha.Keys) }
}

# Draw each pixel as an integer rectangle for exact nearest-neighbor previews.
function Draw-Pixels($graphics,$image,$dx,$dy,$scale) {
    for($y=0;$y -lt $image.Height;$y++) {
        for($x=0;$x -lt $image.Width;$x++) {
            $color=$image.GetPixel($x,$y)
            if($color.A -gt 0) {
                $brush=[Drawing.SolidBrush]::new($color)
                $graphics.FillRectangle($brush,($dx+$x*$scale),($dy+$y*$scale),$scale,$scale)
                $brush.Dispose()
            }
        }
    }
}

$sheet=[Drawing.Bitmap]::new(1020,1220)
$g=[Drawing.Graphics]::FromImage($sheet); $g.Clear([Drawing.Color]::FromArgb(49,49,52))
$font=[Drawing.Font]::new('Consolas',10)
$bg=[Drawing.Bitmap]::FromFile((Join-Path $assetDir 'cabin_background.png'))
$records=@()
for($i=0;$i -le 9;$i++) {
    $name=if($i -eq 0){'bottle.png'}elseif($i -eq 1){'bottle-redesign.png'}else{"bottle-redesign-$i.png"}
    $im=[Drawing.Bitmap]::FromFile((Join-Path $assetDir $name))
    $b=Measure-Sprite $im
    $ok=($b.width -ge 27 -and $b.width -le 29 -and $b.height -eq 12)
    $records += [pscustomobject]@{variant=$i;file=$name;canvas=@($im.Width,$im.Height);bounds=$b;size_compliant=$ok}
    $cx=($i%3)*340; $cy=[Math]::Floor($i/3)*300
    $label=if($i -eq 0){'Originale'}else{"Variante $i"}
    $g.DrawString("$label | canvas $($im.Width)x$($im.Height)",$font,[Drawing.Brushes]::White,$cx+12,$cy+8)
    $g.DrawString("Visibile $($b.width)x$($b.height) | $(if($ok){'OK'}else{'FUORI'})",$font,[Drawing.Brushes]::White,$cx+12,$cy+29)
    # Display visible pixels enlarged; source files retain their native canvas.
    $crop=$im.Clone([Drawing.Rectangle]::new($b.x,$b.y,$b.width,$b.height),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Draw-Pixels $g $crop ($cx+16) ($cy+58) $(if($b.height -gt 16){4}else{9})
    # Static scene-context mockup: left edge fixed at x=364, lower contact y=200.
    $scene=[Drawing.Bitmap]::new(144,40)
    $sg=[Drawing.Graphics]::FromImage($scene)
    $sg.DrawImageUnscaled($bg,-310,-170)
    Draw-Pixels $sg $crop 54 (30-$b.height) 1
    $sg.Dispose()
    $g.DrawString('Contesto cabina (2x)', $font,[Drawing.Brushes]::White,$cx+12,$cy+178)
    # Context crop at 2x, matching the displayed region for each candidate.
    Draw-Pixels $g $scene ($cx+12) ($cy+202) 2
    $scene.Dispose(); $crop.Dispose(); $im.Dispose()
}
# Keep the approved style reference visible beside the comparison.
$ref=[Drawing.Bitmap]::FromFile((Join-Path $root 'godot/assets/graphics/characters/churchill/churchill-stand.png'))
$g.DrawString('Riferimento: Churchill', $font,[Drawing.Brushes]::White,355,910)
Draw-Pixels $g $ref 390 940 2
$ref.Dispose(); $bg.Dispose(); $font.Dispose(); $g.Dispose()
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png')); $sheet.Dispose()
$records | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding utf8
$records | ForEach-Object { "Variante $($_.variant): $($_.canvas -join 'x'), visibile $($_.bounds.width)x$($_.bounds.height), conforme=$($_.size_compliant)" }



