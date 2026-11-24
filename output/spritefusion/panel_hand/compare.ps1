Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
# Misura i file nativi e crea un confronto, senza modificare gli asset.
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$files = @('godot/assets/graphics/ui/panel_hand.png')
$files += @(1..9 | ForEach-Object { $suffix = if ($_ -eq 1) { '' } else { '-' + $_ }; 'godot/assets/graphics/ui/panel_hand-redesign' + $suffix + '.png' })
$files += 'godot/assets/graphics/characters/churchill/churchill-stand.png'
$sheet = [System.Drawing.Bitmap]::new(1200, 1050)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(38, 43, 48))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [System.Drawing.Font]::new('Consolas', 11)
$metrics = @()
for ($i = 0; $i -lt $files.Count; $i++) {
    $im = [System.Drawing.Bitmap]::new((Join-Path $root $files[$i]))
    $minX = $im.Width; $minY = $im.Height; $maxX = -1; $maxY = -1; $alpha = @{}
    for ($y = 0; $y -lt $im.Height; $y++) { for ($x = 0; $x -lt $im.Width; $x++) {
        $a = $im.GetPixel($x, $y).A; $alpha[[int]$a] = 1
        if ($a -gt 0) { $minX = [Math]::Min($minX, $x); $minY = [Math]::Min($minY, $y); $maxX = [Math]::Max($maxX, $x); $maxY = [Math]::Max($maxY, $y) }
    } }
    $w = $maxX - $minX + 1; $h = $maxY - $minY + 1
    $metrics += [pscustomobject]@{ file = $files[$i]; canvas = @($im.Width, $im.Height); bounds = @($minX, $minY, ($maxX + 1), ($maxY + 1)); visible = @($w, $h); alpha = @($alpha.Keys | Sort-Object); size_conformant = ($w -ge 48 -and $w -le 52 -and $h -ge 35 -and $h -le 37) }
    $cx = ($i % 4) * 300; $cy = [Math]::Floor($i / 4) * 350
    $label = if ($i -eq 0) { 'Originale' } elseif ($i -eq 10) { 'Churchill (stile)' } else { 'Variante ' + $i }
    $g.DrawString($label, $font, [System.Drawing.Brushes]::White, $cx + 12, $cy + 10)
    $g.DrawString(('Canvas {0}x{1} / Vis. {2}x{3}' -f $im.Width, $im.Height, $w, $h), $font, [System.Drawing.Brushes]::LightGray, $cx + 12, $cy + 32)
    $g.DrawImage($im, [int]($cx + 20), [int]($cy + 60), $im.Width, $im.Height)
    $scale = if ($i -eq 10) { 2 } else { 3 }
    $g.DrawImage($im, [int]($cx + 20), [int]($cy + 140), ($im.Width * $scale), ($im.Height * $scale))
    $im.Dispose()
}
$metrics | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $PSScriptRoot 'measurements.json')
$sheet.Save((Join-Path $PSScriptRoot 'comparison.png'))
$font.Dispose(); $g.Dispose(); $sheet.Dispose()
$metrics | Select-Object file, canvas, visible, size_conformant | Format-Table -AutoSize
