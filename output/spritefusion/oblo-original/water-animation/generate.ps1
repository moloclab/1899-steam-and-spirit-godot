# Costruisce un ciclo locale dalla variante approvata, modificando solo la superficie dell'acqua.
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$native = [Drawing.Bitmap]::FromFile((Join-Path $project 'godot/assets/graphics/ep01_cabin/oblo-original-redesign-2.png'))
$source = $native.Clone([Drawing.Rectangle]::new(2,2,43,43), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$native.Dispose()
$source.Save((Join-Path $PSScriptRoot 'static-approved.png'), [Drawing.Imaging.ImageFormat]::Png)
$count = 12
$sheet = [Drawing.Bitmap]::new(43*$count,43)
$preview = [Drawing.Bitmap]::new(43*6*4,43*2*4)
$graphics = [Drawing.Graphics]::FromImage($preview)
$graphics.Clear([Drawing.Color]::FromArgb(55,55,59))
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half

# La selezione cromatica esclude ottone, contorni e ombre del bordo interno.
function Test-Water([Drawing.Color]$color) {
    return $color.A -eq 255 -and $color.G -gt ($color.R+12) -and $color.B -gt ($color.R+12)
}
for($frame=0;$frame -lt $count;$frame++) {
    $image = $source.Clone([Drawing.Rectangle]::new(0,0,43,43),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $phase = 2*[Math]::PI*$frame/$count
    for($x=9;$x -le 33;$x++) {
        # La differenza di fase lascia il primo fotogramma identico alla variante scelta.
        $wave = 2*[Math]::PI*($x-9)/24
        $shift = [int][Math]::Round(0.7*([Math]::Sin($wave-$phase)-[Math]::Sin($wave))+0.55*[Math]::Sin($phase))
        for($y=18;$y -le 26;$y++) {
            $original = $source.GetPixel($x,$y)
            if(!(Test-Water $original)) { continue }
            # Il moto si attenua in profondita; riflesso alto e ombre del vetro restano fermi.
            $vertical = if($y -le 23){$shift}elseif($y -le 25){[int][Math]::Round($shift*0.5)}else{0}
            $horizontal = if($y -ge 20 -and $y -le 25){[int][Math]::Round([Math]::Sin($phase))}else{0}
            $sampleX = [Math]::Max(9,[Math]::Min(33,($x-$horizontal)))
            $sampleY = $y-$vertical
            $sample = $source.GetPixel($sampleX,$sampleY)
            if(Test-Water $sample) { $image.SetPixel($x,$y,$sample) }
        }
    }
    # Copia i pixel esatti nel foglio: nessuna interpolazione o modifica dell'alpha.
    for($y=0;$y -lt 43;$y++){for($x=0;$x -lt 43;$x++){$sheet.SetPixel(($frame*43+$x),$y,$image.GetPixel($x,$y))}}
    $image.Save((Join-Path $PSScriptRoot ('frame-'+$frame.ToString('00')+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    $graphics.DrawImage($image,[Drawing.Rectangle]::new(($frame%6)*172,[int][Math]::Floor($frame/6)*172,172,172),0,0,43,43,[Drawing.GraphicsUnit]::Pixel)
    $image.Dispose()
}
$sheet.Save((Join-Path $project 'godot/assets/graphics/ep01_cabin/oblo.png'),[Drawing.Imaging.ImageFormat]::Png)
$preview.Save((Join-Path $PSScriptRoot 'frames.png'),[Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose();$preview.Dispose();$sheet.Dispose();$source.Dispose()
