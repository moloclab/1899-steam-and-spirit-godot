# Misura i file nativi e crea confronti senza modificare gli asset.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$entries = @(@{variant=0;file='godot/assets/graphics/ep01_corridor/ax_box.png'})
$downloads = Get-Content (Join-Path $PSScriptRoot 'downloads.json') -Raw | ConvertFrom-Json
foreach($download in $downloads){ $entries += $download }
$canvas = New-Object System.Drawing.Bitmap 1100,660
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(48,51,55))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = New-Object System.Drawing.Font 'Arial',12
$measurements = @()
$context = New-Object System.Drawing.Bitmap 1100,760
$cg = [System.Drawing.Graphics]::FromImage($context)
$cg.Clear([System.Drawing.Color]::FromArgb(48,51,55))
$cg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$cg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$bg = [System.Drawing.Bitmap]::FromFile((Join-Path $root 'godot/assets/graphics/ep01_corridor/corridor_background.png'))
for($i=0;$i -lt $entries.Count;$i++) {
    $entry=$entries[$i]
    $img=[System.Drawing.Bitmap]::FromFile((Join-Path $root $entry.file))
    $minX=$img.Width; $minY=$img.Height; $maxX=-1; $maxY=-1; $alpha=@{}
    for($y=0;$y -lt $img.Height;$y++){for($x=0;$x -lt $img.Width;$x++){
        $a=$img.GetPixel($x,$y).A; $alpha[[int]$a]=$true
        if($a -gt 0){$minX=[Math]::Min($minX,$x);$minY=[Math]::Min($minY,$y);$maxX=[Math]::Max($maxX,$x);$maxY=[Math]::Max($maxY,$y)}
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $m=[pscustomobject]@{variant=$entry.variant;file=$entry.file;canvas=@($img.Width,$img.Height);bounds=@($minX,$minY,$w,$h);alpha=@($alpha.Keys | Sort-Object);size_conforms=($w -ge 35 -and $w -le 37 -and $h -ge 42 -and $h -le 46)}
    $measurements += $m
    $label=if($i -eq 0){'Originale'}else{'V'+$i}
    $px=($i%5)*220; $py=[Math]::Floor($i/5)*330
    $g.DrawString("$label - ${w}x${h}",$font,[System.Drawing.Brushes]::White,$px+8,$py+8)
    $g.DrawImage($img,($px+14),($py+40),($img.Width*4),($img.Height*4))
    # Mostra anche i pixel nativi, separati dall'ingrandimento.
    $g.DrawImage($img,($px+14),($py+250),$img.Width,$img.Height)
    $cx=($i%5)*220; $cy=[Math]::Floor($i/5)*380
    $cg.DrawString($label+' - contesto 3x',$font,[System.Drawing.Brushes]::White,$cx+6,$cy+8)
    # Anteprima statica del fondale: sagoma ancorata a (200,108), scala 3x.
    $tile=New-Object System.Drawing.Bitmap 70,105
    $tg=[System.Drawing.Graphics]::FromImage($tile)
    $tg.DrawImage($bg,(New-Object System.Drawing.Rectangle 0,0,70,105),180,80,70,105,[System.Drawing.GraphicsUnit]::Pixel)
    $tg.DrawImage($img,(20-$minX),(28-$minY),$img.Width,$img.Height)
    $cg.DrawImage($tile,$cx+5,$cy+40,210,315)
    $tg.Dispose();$tile.Dispose();$img.Dispose()
}
$measurements | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'measurements.json') -Encoding UTF8
$canvas.Save((Join-Path $PSScriptRoot 'comparison.png'))
$context.Save((Join-Path $PSScriptRoot 'context.png'))
$bg.Dispose();$g.Dispose();$cg.Dispose();$canvas.Dispose();$context.Dispose();$font.Dispose()
$measurements | Select-Object variant,canvas,bounds,size_conforms | Format-Table
