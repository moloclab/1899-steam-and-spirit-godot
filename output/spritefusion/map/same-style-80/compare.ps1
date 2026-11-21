# Misura i pixel visibili e crea confronti senza alterare gli asset nativi.
Add-Type -AssemblyName System.Drawing
$trialPath = $PSScriptRoot
$projectPath = (Resolve-Path (Join-Path $trialPath '../../../..')).Path
$assetPath = Join-Path $projectPath 'godot/assets/graphics/ep01_cabin'
$paths = @((Join-Path $assetPath 'map.png'))
for ($number=1; $number -le 9; $number++) {
    $name = if ($number -eq 1) { 'map-redesign.png' } else { "map-redesign-$number.png" }
    $paths += Join-Path $assetPath $name
}
$sheet = [System.Drawing.Bitmap]::new(1050, 1260)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(49,49,52))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [System.Drawing.Font]::new('Arial',12)
$measurements = @()
for ($index=0; $index -lt $paths.Count; $index++) {
    $bitmap = [System.Drawing.Bitmap]::FromFile($paths[$index])
    $left=$bitmap.Width; $top=$bitmap.Height; $right=-1; $bottom=-1
    $alphaValues = [System.Collections.Generic.HashSet[int]]::new()
    for ($row=0; $row -lt $bitmap.Height; $row++) {
        for ($col=0; $col -lt $bitmap.Width; $col++) {
            $alpha=$bitmap.GetPixel($col,$row).A
            [void]$alphaValues.Add([int]$alpha)
            if ($alpha -gt 0) {
                $left=[Math]::Min($left,$col); $right=[Math]::Max($right,$col)
                $top=[Math]::Min($top,$row); $bottom=[Math]::Max($bottom,$row)
            }
        }
    }
    $width=$right-$left+1; $height=$bottom-$top+1
    $measurement=[pscustomobject]@{Index=$index;File=[IO.Path]::GetFileName($paths[$index]);Canvas=@($bitmap.Width,$bitmap.Height);Bounds=@($left,$top,$width,$height);Alpha=@($alphaValues);WithinTolerance=($width -ge 57 -and $width -le 63 -and $height -ge 69 -and $height -le 75)}
    $measurements += $measurement
    $cellX=($index % 3)*350; $cellY=[Math]::Floor($index/3)*315
    $label=if($index -eq 0){'Originale'}else{"Variante $index"}
    $graphics.DrawString("$label - soggetto ${width}x${height}",$font,[System.Drawing.Brushes]::White,($cellX+12),($cellY+8))
    $graphics.DrawImage($bitmap,[System.Drawing.Rectangle]::new(($cellX+55),($cellY+40),($bitmap.Width*3),($bitmap.Height*3)))
    $bitmap.Dispose()
}
$sheet.Save((Join-Path $trialPath 'comparison.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$measurements | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $trialPath 'validation.json')
$graphics.Dispose(); $sheet.Dispose(); $font.Dispose()
$measurements | Select-Object Index,Canvas,Bounds,WithinTolerance | Format-Table -AutoSize
