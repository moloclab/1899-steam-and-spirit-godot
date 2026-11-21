# Anteprima statica del fondale e degli oggetti vicini alle coordinate della scena.
# Non modifica texture o scene e non sostituisce la verifica dentro Godot.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path "$PSScriptRoot/../../../..").Path
$validation=Get-Content -Raw "$PSScriptRoot/validation.json" | ConvertFrom-Json
$sheet=New-Object System.Drawing.Bitmap 1400,560
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(32,34,37))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font=New-Object System.Drawing.Font 'Consolas',10
$g.DrawString('Contesto statico / fondale e lavabo / 2x / non e una cattura Godot',$font,[System.Drawing.Brushes]::White,12,10)
for($i=0;$i -lt 10;$i++) {
    $canvas=New-Object System.Drawing.Bitmap 136,112
    $cg=[System.Drawing.Graphics]::FromImage($canvas)
    $bg=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/cabin_background.png")
    $cg.DrawImageUnscaled($bg,-200,-104);$bg.Dispose()
    $sink=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/sink.png")
    $cg.DrawImageUnscaled($sink,72,40);$sink.Dispose()
    if($i -eq 0){$path="$root/godot/assets/graphics/ep01_cabin/como.png";$bounds=@(0,0,40,36);$label='Precedente'}
    else{$v=$validation[$i-1];$path=Join-Path $root $v.file;$bounds=$v.visible_bounds;$label="V$i"}
    $im=[System.Drawing.Image]::FromFile($path)
    # Allineamento alla quota del pavimento y=200, senza scalare i pixel del soggetto.
    $dest=New-Object System.Drawing.Rectangle 24,(96-$bounds[3]),$bounds[2],$bounds[3]
    $cg.DrawImage($im,$dest,$bounds[0],$bounds[1],$bounds[2],$bounds[3],[System.Drawing.GraphicsUnit]::Pixel)
    $im.Dispose()
    $quill=[System.Drawing.Image]::FromFile("$root/godot/assets/graphics/ep01_cabin/feather.png")
    $cg.DrawImageUnscaled($quill,32,32);$quill.Dispose();$cg.Dispose()
    $x=($i%5)*280;$y=40+[int][Math]::Floor($i/5)*260
    $g.DrawString($label,$font,[System.Drawing.Brushes]::White,($x+4),$y)
    $g.DrawImage($canvas,$x,($y+20),272,224);$canvas.Dispose()
}
$g.Dispose();$font.Dispose();$sheet.Save("$PSScriptRoot/context.png");$sheet.Dispose()
