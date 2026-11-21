# Misura i file nativi e prepara confronti senza modificarne i pixel.
Add-Type -AssemblyName System.Drawing
$root = (Get-Location).Path
$dest = Join-Path $root 'output/spritefusion/door_sub/edit-v4'
$files = @('door_sub.png','door_sub-redesign-4.png','door_sub-redesign-5.png','door_sub-redesign-6.png')
$records = @()
$sheet = [Drawing.Bitmap]::new(1400, 470)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(72,72,76))
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [Drawing.Font]::new('Arial',11)
$background = [Drawing.Bitmap]::new((Join-Path $root 'godot/assets/graphics/ep01_cabin/cabin_background.png'))
$scenes = [Drawing.Bitmap]::new(1120,360)
$sg = [Drawing.Graphics]::FromImage($scenes)
$sg.Clear([Drawing.Color]::FromArgb(72,72,76))
$sg.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$sg.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
for($i=0;$i -lt 5;$i++) {
    # L'ultima colonna mostra il riferimento stilistico approvato.
    $path = if($i -lt 4){Join-Path $root ('godot/assets/graphics/ep01_cabin/'+$files[$i])}else{Join-Path $root 'godot/assets/graphics/characters/churchill/churchill-stand.png'}
    $im = [Drawing.Bitmap]::new($path)
    $minX=$im.Width; $minY=$im.Height; $maxX=-1; $maxY=-1; $alphas=@{}
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $a=$im.GetPixel($x,$y).A; $alphas[$a]=1
        if($a -gt 0){$minX=[Math]::Min($minX,$x);$minY=[Math]::Min($minY,$y);$maxX=[Math]::Max($maxX,$x);$maxY=[Math]::Max($maxY,$y)}
    }}
    $w=$maxX-$minX+1; $h=$maxY-$minY+1
    $label=if($i -eq 0){'Originale'}elseif($i -eq 4){'Churchill'}else{'Variante '+($i+3)}
    $g.DrawString($label,$font,[Drawing.Brushes]::White,($i*280+12),8)
    $g.DrawString("Canvas $($im.Width)x$($im.Height) / soggetto ${w}x${h}",$font,[Drawing.Brushes]::White,($i*280+12),29)
    $g.DrawImage($im,[Drawing.Rectangle]::new(($i*280+70),55,$im.Width,$im.Height),0,0,$im.Width,$im.Height,[Drawing.GraphicsUnit]::Pixel)
    $g.DrawImage($im,[Drawing.Rectangle]::new(($i*280+12),195,($im.Width*2),($im.Height*2)),0,0,$im.Width,$im.Height,[Drawing.GraphicsUnit]::Pixel)
    if($i -lt 4){
        $records += [PSCustomObject]@{file=$files[$i];canvas=@($im.Width,$im.Height);bounds=@($minX,$minY,($maxX+1),($maxY+1));visible=@($w,$h);alpha=@($alphas.Keys|Sort-Object);size_pass=($w -ge 73 -and $w -le 79 -and $h -ge 111 -and $h -le 121);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
        # Anteprima statica: allinea la base e il centro del soggetto allo spazio della porta.
        $crop = [Drawing.Bitmap]::new(140,160)
        $cg=[Drawing.Graphics]::FromImage($crop)
        $cg.DrawImage($background,[Drawing.Rectangle]::new(0,0,140,160),500,50,140,160,[Drawing.GraphicsUnit]::Pixel)
        $cg.DrawImageUnscaled($im,([int](82-$w/2)-$minX),(150-$h-$minY))
        $sg.DrawImage($crop,[Drawing.Rectangle]::new(($i*280),32,280,320),0,0,140,160,[Drawing.GraphicsUnit]::Pixel)
        $sg.DrawString($label,$font,[Drawing.Brushes]::White,($i*280+12),8)
        $cg.Dispose();$crop.Dispose()
    }
    $im.Dispose()
}
$records | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $dest 'validation.json')
$sheet.Save((Join-Path $dest 'comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
$scenes.Save((Join-Path $dest 'cabin-preview.png'),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$sg.Dispose();$sheet.Dispose();$scenes.Dispose();$font.Dispose();$background.Dispose()
$records | ConvertTo-Json -Depth 5
