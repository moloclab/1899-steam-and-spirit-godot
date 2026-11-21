Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path

# Misura canvas, sagoma visibile e alpha senza alterare le immagini native.
function Measure-Sprite([string]$path) {
    $im = [Drawing.Bitmap]::new($path)
    $left=$im.Width; $top=$im.Height; $right=-1; $bottom=-1
    $alpha=[Collections.Generic.HashSet[int]]::new()
    for($y=0;$y -lt $im.Height;$y++){for($x=0;$x -lt $im.Width;$x++){
        $a=$im.GetPixel($x,$y).A; [void]$alpha.Add([int]$a)
        if($a -gt 0){$left=[Math]::Min($left,$x);$top=[Math]::Min($top,$y);$right=[Math]::Max($right,$x);$bottom=[Math]::Max($bottom,$y)}
    }}
    $record=[PSCustomObject]@{file=[IO.Path]::GetFileName($path);canvas=@($im.Width,$im.Height);bounds=@($left,$top,($right+1),($bottom+1));visible=@(($right-$left+1),($bottom-$top+1));alpha=@($alpha | Sort-Object)}
    $im.Dispose(); return $record
}

# Ingrandisce soltanto le anteprime con nearest neighbor, mantenendo intatti gli output.
function Draw-Pixels($g,$im,[int]$x,[int]$y,[int]$factor,[Drawing.Rectangle]$src) {
    $dst=[Drawing.Rectangle]::new($x,$y,$src.Width*$factor,$src.Height*$factor)
    $g.DrawImage($im,$dst,$src,[Drawing.GraphicsUnit]::Pixel)
}
$files=@('bed-original.png','bed-redesign-2.png','bed-redesign-3.png','bed-redesign-4.png','bed-redesign-5.png')
$records=@($files | ForEach-Object { Measure-Sprite (Join-Path $PSScriptRoot $_) })
$records | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'validation.json') -Encoding UTF8
$sheet=[Drawing.Bitmap]::new(1000,1180)
$g=[Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(46,49,53))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
$font=[Drawing.Font]::new('Arial',13)
for($i=0;$i -lt $files.Count;$i++) {
    $im=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot $files[$i]))
    $r=$records[$i]; $row=$i*230
    $label=if($i -eq 0){'Originale'}else{"Variante $($i+1)"}
    $g.DrawString("$label - canvas $($r.canvas -join 'x') - soggetto $($r.visible -join 'x')",$font,[Drawing.Brushes]::White,18,$row+8)
    $src=[Drawing.Rectangle]::new($r.bounds[0],$r.bounds[1],$r.visible[0],$r.visible[1])
    Draw-Pixels $g $im 18 ($row+45) 1 $src
    Draw-Pixels $g $im 200 ($row+45) 3 $src
    $im.Dispose()
}
$g.DrawString('Riferimenti approvati (3x): Churchill e como', $font,[Drawing.Brushes]::White,660,15)
foreach($ref in @(@('characters/churchill/churchill-stand.png',680),@('ep01_cabin/como.png',850))) {
    $im=[Drawing.Bitmap]::new((Join-Path $root "godot/assets/graphics/$($ref[0])"))
    Draw-Pixels $g $im $ref[1] 55 3 ([Drawing.Rectangle]::new(0,0,$im.Width,$im.Height)); $im.Dispose()
}
$g.Dispose();$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'));$sheet.Dispose()

# Ricompone il contesto statico della scena; per le varianti allinea il bordo inferiore a y=200.
$context=[Drawing.Bitmap]::new(640,850)
$cg=[Drawing.Graphics]::FromImage($context);$cg.Clear([Drawing.Color]::FromArgb(46,49,53))
$cg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$cg.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
for($i=0;$i -lt $files.Count;$i++) {
    $scene=[Drawing.Bitmap]::new((Join-Path $root 'godot/assets/graphics/ep01_cabin/cabin_background.png'))
    $sg=[Drawing.Graphics]::FromImage($scene)
    foreach($obj in @(@('map_magnet.png',68,64),@('como.png',224,163),@('sink.png',272,138),@('feather.png',232,136))) {
        $im=[Drawing.Bitmap]::new((Join-Path $root "godot/assets/graphics/ep01_cabin/$($obj[0])"));$sg.DrawImageUnscaled($im,$obj[1],$obj[2]);$im.Dispose()
    }
    $bed=[Drawing.Bitmap]::new((Join-Path $PSScriptRoot $files[$i]));$r=$records[$i]
    $sg.DrawImageUnscaled($bed,(18-$r.bounds[0]),(200-$r.bounds[3]));$bed.Dispose();$sg.Dispose()
    $label=if($i -eq 0){'Originale'}else{"Variante $($i+1)"}
    $cg.DrawString("$label - anteprima statica, base y=200",$font,[Drawing.Brushes]::White,8,($i*170+3))
    Draw-Pixels $cg $scene 0 ($i*170+28) 2 ([Drawing.Rectangle]::new(0,130,320,70))
    $scene.Dispose()
}
$cg.Dispose();$context.Save((Join-Path $PSScriptRoot 'scene-comparison.png'));$context.Dispose();$font.Dispose()
$records | ConvertTo-Json -Depth 5
