Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../../..").Path
$sourcePath = "$root/godot/assets/graphics/ep01_cabin/inventory_bottle-redesign-7.png"
$targetPath = "$root/godot/assets/graphics/ep01_cabin/inventory_bottle.png"
# Centra i pixel nativi della variante approvata, senza ricampionamento.
$source = [Drawing.Bitmap]::FromFile($sourcePath)
$result = [Drawing.Bitmap]::new(50,50,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
for($y=0;$y -lt 45;$y++){for($x=0;$x -lt 15;$x++){
    $result.SetPixel(($x+17),($y+2),$source.GetPixel(($x+16),($y+1)))
}}
$result.Save($targetPath,[Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()
# Verifica la corrispondenza dei pixel e la trasparenza dei margini.
$saved = [Drawing.Bitmap]::FromFile($targetPath)
$visibleCount=0
for($y=0;$y -lt 50;$y++){for($x=0;$x -lt 50;$x++){
    $pixel=$saved.GetPixel($x,$y)
    if($pixel.A -ne 0 -and $pixel.A -ne 255){throw 'Alpha non binario'}
    if($x -ge 17 -and $x -lt 32 -and $y -ge 2 -and $y -lt 47){
        if($pixel.ToArgb() -ne $source.GetPixel(($x-17+16),($y-2+1)).ToArgb()){throw 'Pixel differente dal nativo'}
    } elseif($pixel.A -ne 0){throw 'Margine non trasparente'}
    if($pixel.A -gt 0){$visibleCount++}
}}
$saved.Dispose();$source.Dispose()
$data=Get-Content -Raw "$PSScriptRoot/generation.json" | ConvertFrom-Json
$data.decision='V7 approvata dall utente il 2026-11-25, inclusa deroga dimensionale 15x45. Integrata senza ricampionamento su canvas 50x50, posizione (17,2).'
$data | ConvertTo-Json -Depth 20 | Set-Content "$PSScriptRoot/generation.json" -Encoding utf8
Write-Output "V7 integrata: canvas 50x50, soggetto 15x45 a (17,2), alpha binario, pixel identici al nativo; $visibleCount pixel opachi."
