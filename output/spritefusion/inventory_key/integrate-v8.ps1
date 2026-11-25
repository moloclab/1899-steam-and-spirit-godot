Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$assets = Join-Path $root 'godot/assets/graphics/ep01_cabin'
$native = [System.Drawing.Bitmap]::FromFile((Join-Path $assets 'inventory_key-redesign-8.png'))
$final = [System.Drawing.Bitmap]::new(50,50)
try {
    # Centra i bounds nativi 12x31 senza interpolazione: margini 19/19 e 9/10.
    for($y=0;$y -lt 31;$y++){for($x=0;$x -lt 12;$x++){
        $final.SetPixel(19+$x,9+$y,$native.GetPixel(10+$x,$y))
    }}
    $final.Save((Join-Path $assets 'inventory_key.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $final.Dispose()
    $native.Dispose()
}
# Rilegge il PNG salvato e verifica ogni pixel, compresi i margini trasparenti.
$native = [System.Drawing.Bitmap]::FromFile((Join-Path $assets 'inventory_key-redesign-8.png'))
$saved = [System.Drawing.Bitmap]::FromFile((Join-Path $assets 'inventory_key.png'))
try {
    if($saved.Width -ne 50 -or $saved.Height -ne 50){throw 'Canvas errato'}
    for($y=0;$y -lt 50;$y++){for($x=0;$x -lt 50;$x++){
        $actual=$saved.GetPixel($x,$y)
        if($x -ge 19 -and $x -lt 31 -and $y -ge 9 -and $y -lt 40){
            if($actual.ToArgb() -ne $native.GetPixel($x-19+10,$y-9).ToArgb()){throw 'Pixel modificato'}
        } elseif($actual.A -ne 0){throw 'Margine non trasparente'}
        if($actual.A -ne 0 -and $actual.A -ne 255){throw 'Alpha non binario'}
    }}
    Write-Output 'OK: canvas 50x50, bounds (19,9,12,31), pixel V8 identici, alpha binario.'
} finally {
    $saved.Dispose()
    $native.Dispose()
}
