# Converte solo gli asset necessari, senza modificare EP01. Eseguire con PowerShell su Windows.
# Sorgente: la cartella EP01 accanto a godot. Destinazione: godot/assets/graphics/original e scenes/rooms.
# ATTENZIONE: rieseguire lo script rigenera PNG, animazioni e scene .tscn, sovrascrivendo
# anche eventuali modifiche manuali fatte alle due scene nell'editor.
# L'importazione è già stata effettuata: questo strumento non serve per avviare il gioco.
# Nessun comando di questo script esegue o modifica il JavaScript del gioco originale.

# Interrompe l'importazione al primo errore, invece di proseguire con risorse mancanti.
$ErrorActionPreference = 'Stop'
# System.Drawing decodifica GIF e JPEG e permette di salvare PNG con trasparenza su Windows.
Add-Type -AssemblyName System.Drawing
# I percorsi derivano dalla posizione dello script, non dalla cartella corrente della shell.
$projectDir = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path (Split-Path $projectDir -Parent) 'EP01'
$assetDir = Join-Path $projectDir 'assets/graphics/original'
New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
$names = @('panel_hand','panel_mouth','panel_exit','mapMagnet','map','como','sink','feather','oblo','interphone','interphoneTube','doorSub','bed','bottle','churchillStand','churchillWalk','O_bottle','O_feather','O_magnet','O_magnetFeather','O_key','label','axBox','smoker','r2_wireH','wireV','lamp','stair','manHole')
# La lista precedente include solo le risorse richieste dalle due stanze e dall'interfaccia.
# Questo dizionario servirà anche per scegliere Sprite2D oppure AnimatedSprite2D nelle scene.
$frameCounts = @{}
foreach ($name in $names) {
    $image = [System.Drawing.Image]::FromFile((Join-Path $sourceDir "img/$name.gif"))
    # La dimensione Time enumera i fotogrammi del GIF; per le immagini statiche ne restituisce uno.
    $count = $image.GetFrameCount([System.Drawing.Imaging.FrameDimension]::Time)
    # I pannelli delle azioni sono immagini UI statiche: manteniamo il PNG senza suffisso già usato dal menu.
    # Alcuni GIF contengono un secondo fotogramma; qui non serve una risorsa SpriteFrames.
    if ($name -like 'panel_*') { $count = 1 }
    $frameCounts[$name] = $count
    for ($i = 0; $i -lt $count; $i++) {
        # Il decoder porta l'immagine sul fotogramma desiderato prima del disegno sul nuovo bitmap.
        $image.SelectActiveFrame([System.Drawing.Imaging.FrameDimension]::Time, $i) | Out-Null
        $bitmap = New-Object System.Drawing.Bitmap $image.Width,$image.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)
        # Le immagini statiche mantengono il nome; le animate ricevono un suffisso a partire da _0.
        $suffix = if ($count -eq 1) { '' } else { "_$i" }
        $bitmap.Save((Join-Path $assetDir "$name$suffix.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        # Istanze GDI+ native: liberarle a ogni fotogramma evita di accumulare risorse grafiche.
        $graphics.Dispose()
        $bitmap.Dispose()
    }
    if ($count -gt 1) {
        # La risorsa .tres elenca i PNG come Texture2D esterne e li associa a un'animazione ciclica.
        # load_steps conta le texture più la risorsa SpriteFrames stessa.
        $resource = "[gd_resource type=`"SpriteFrames`" load_steps=$($count+1) format=3]`n`n"
        $frames = @()
        for ($i = 0; $i -lt $count; $i++) {
            $resource += "[ext_resource type=`"Texture2D`" path=`"res://assets/graphics/original/$($name)_$i.png`" id=`"$($i+1)`"]`n"
            $frames += "{`"duration`": 1.0, `"texture`": ExtResource(`"$($i+1)`")}"
        }
        # Velocità di ripiego se il GIF non specifica il tempo tra fotogrammi.
        $speed = 8.0
        if ($image.PropertyIdList -contains 20736) {
            # Il metadato GIF 20736 contiene i ritardi in centesimi di secondo.
            # Per questo prototipo usiamo il primo ritardo come velocità uniforme dell'animazione.
            $delay = [BitConverter]::ToInt32($image.GetPropertyItem(20736).Value, 0)
            if ($delay -gt 0) { $speed = 100.0 / $delay }
        }
        # Godot richiede il punto decimale anche quando Windows usa la virgola nelle impostazioni italiane.
        $speedText = $speed.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        $resource += "`n[resource]`nanimations = [{`"frames`": [$($frames -join ', ')], `"loop`": true, `"name`": &`"default`", `"speed`": $speedText}]`n"
        Set-Content -LiteralPath (Join-Path $assetDir "$name.tres") -Value $resource -Encoding utf8
    }
    $image.Dispose()
}

# Le dimensioni del fondale originale sono più grandi delle stanze: ritaglio senza ridimensionamento.
$background = [System.Drawing.Image]::FromFile((Join-Path $sourceDir 'img/room.jpg'))
foreach ($room in @(@('cabin',648), @('corridor',892))) {
    # Il bitmap di destinazione fa da ritaglio: il fondale viene disegnato alle dimensioni originali.
    # Si conservano i primi 275 pixel di altezza e la larghezza dichiarata per ciascuna stanza.
    $bitmap = New-Object System.Drawing.Bitmap ([int]$room[1]),275
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.DrawImage($background, 0, 0, $background.Width, $background.Height)
    $bitmap.Save((Join-Path $assetDir "$($room[0])_background.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$background.Dispose()

# Il catalogo assets/data/dialogue.json è curato manualmente e non viene rigenerato.
# Le risposte delle scene usano le stesse chiavi descrittive del catalogo.

# Genera scene native Godot con un nodo per ogni oggetto della stanza originale.
# Le etichette servono al giocatore; gli alias mantengono gli ID stabili usati dall'interfaccia.
$labels = @{mapMagnet='Mappa e calamita';como='Comodino';sinkNormal='Lavandino';feather="Penna d'oca";oblo1='Oblò';oblo2='Oblò';interphone='Interfono';door='Porta della cabina';bed='Letto';bottle='Bourbon';door_cabina='Torna alla cabina';label_cabina='Targa Churchill';axBoxClose='Scure di emergenza';label_ax='Targa antincendio';door_camerata='Camerata';smoker='Marinaio';door_kelvin='Cabina di Kelvin';label_kelvin='Targa Kelvin';wireVNormal='Filo elettrico';lampBlink='Lampada';stair='Ponte superiore';manhole='Ponte inferiore'}
$ids = @{mapMagnet='map';sinkNormal='sink';door_cabina='return';axBoxClose='axe'}
# La conversione sceglie il comportamento una volta sola. A runtime le scene hanno già il proprio script.
# Le risposte non elencate restano i segnaposto precedenti, senza aggiungere contenuti al corridoio.
$behaviors = @{map='cabin_map';sink='cabin_sink';door='cabin_door';return='room_exit';bottle='collectible';feather='collectible'}
$examinations = @{como='cabin.nightstand.examine';feather='cabin.feather.examine';bottle='cabin.bottle.examine';oblo1='cabin.porthole.examine';oblo2='cabin.porthole.examine';interphone='cabin.interphone.examine';door='cabin.door.examine';bed='cabin.bed.examine';return='corridor.cabin_sign.examine';axe='corridor.axe.examine';smoker='corridor.smoker.examine'}
$interactions = @{como='cabin.nightstand.interact';oblo1='cabin.porthole.interact';oblo2='cabin.porthole.interact';interphone='cabin.interphone.conversation';bed='cabin.bed.interact';axe='corridor.axe.case_closed';smoker='corridor.smoker.conversation';door='cabin.door.exit';return='cabin.door.return'}
foreach ($room in @(@('cabin',1), @('corridor',2))) {
    # Associa i nomi delle scene Godot ai numeri delle stanze HTML del gioco originale.
    $html = Get-Content -Raw -LiteralPath (Join-Path $sourceDir "rooms/room$($room[1]).html")
    # Gruppi catturati: ID del div, attributi del div, nome immagine e attributi dell'immagine.
    # La struttura prevista è quella specifica di room1.html e room2.html.
    $objects = [regex]::Matches($html, '<div id="([^"]+)"([^>]*)>\s*<img src="img/([^"]+)"([^>]*)/>')
    $resources = "[ext_resource type=`"Script`" path=`"res://scripts/hotspot.gd`" id=`"hotspot`"]`n[ext_resource type=`"Texture2D`" path=`"res://assets/graphics/original/$($room[0])_background.png`" id=`"background`"]`n"
    $nodes = "[node name=`"$($room[0].ToUpperInvariant())`" type=`"Node2D`"]`n`n[node name=`"Background`" type=`"Sprite2D`" parent=`".`"]`ntexture = ExtResource(`"background`")`ncentered = false`n`n"
    # Risorse e nodi vengono accumulati separatamente: nel .tscn le dichiarazioni precedono l'albero.
    # Le prime due risorse sono lo script Hotspot e il fondale della stanza.
    $resourceCount = 2
    # Deduplica gli script usati più volte nella stessa scena (per esempio i due raccoglibili).
    $declaredBehaviors = @{}
    foreach ($obj in $objects) {
        $nodeName = $obj.Groups[1].Value
        $attrs = $obj.Groups[2].Value
        # Fondale e personaggio sono gestiti a parte. I div hide rappresentano varianti inizialmente inattive.
        # Le varianti usate nell'enigma vengono aggiornate dagli hotspot, senza duplicare i nodi nascosti.
        if ($nodeName -in @('room','pg') -or $attrs -match '\bhide\b') { continue }
        $name = [System.IO.Path]::GetFileNameWithoutExtension($obj.Groups[3].Value)
        if ($attrs -notmatch 'top:([\d-]+)px;left:([\d-]+)px;') { continue }
        # CSS top/left diventano y/x locali di Godot, mantenendo le coordinate del gioco originale.
        $x = [int]$Matches[2]; $y = [int]$Matches[1]
        $isAnimated = $frameCounts[$name] -gt 1
        $resourceType = if ($isAnimated) { 'SpriteFrames' } else { 'Texture2D' }
        $ext = if ($isAnimated) { 'tres' } else { 'png' }
        $resources += "[ext_resource type=`"$resourceType`" path=`"res://assets/graphics/original/$name.$ext`" id=`"$nodeName`"]`n"
        $resourceCount++
        $nodes += "[node name=`"$nodeName`" type=`"Node2D`" parent=`".`"]`nposition = Vector2($x, $y)`n"
        # Il letto è un oggetto in primo piano e deve passare davanti a Churchill (z_index = 1).
        if ($nodeName -eq 'bed') { $nodes += "z_index = 2`n" }
        if ($attrs -match '\bobj\b') {
            # Solo i div obj diventano cliccabili. Gli altri elementi restano decorazioni della stanza.
            # Le dimensioni dell'immagine originale definiscono il rettangolo dell'hotspot.
            $im = [System.Drawing.Image]::FromFile((Join-Path $sourceDir "img/$name.gif"))
            $id = if ($ids.ContainsKey($nodeName)) { $ids[$nodeName] } else { $nodeName }
            $scriptId = 'hotspot'
            if ($behaviors.ContainsKey($id)) {
                $behavior = $behaviors[$id]
                $scriptId = "behavior_$behavior"
                if (-not $declaredBehaviors.ContainsKey($behavior)) {
                    $resources += "[ext_resource type=`"Script`" path=`"res://scripts/hotspots/$behavior.gd`" id=`"$scriptId`"]`n"
                    $resourceCount++
                    $declaredBehaviors[$behavior] = $true
                }
            }
            $label = $labels[$nodeName]
            $rightEdge = if ($room[0] -eq 'cabin') { 624 } else { 868 }
            # Avvicinamento verso il centro dell'oggetto, con un margine per restare dentro la stanza.
            $approach = [Math]::Max(24, [Math]::Min($rightEdge, $x + $im.Width / 2))
            $nodes += "script = ExtResource(`"$scriptId`")`nhotspot_id = `"$id`"`ndisplay_name = `"$label`"`nhit_size = Vector2($($im.Width), $($im.Height))`napproach_x = $approach.0`n"
            # Parametri esportati: gli oggetti statici e raccoglibili condividono gli script ma non le risposte.
            if ($examinations.ContainsKey($id)) { $nodes += "examine_response = `"$($examinations[$id])`"`n" }
            if ($interactions.ContainsKey($id)) { $nodes += "interaction_response = `"$($interactions[$id])`"`n" }
            if ($id -in @('bottle','feather')) {
                $response = if ($id -eq 'bottle') { 'cabin.bottle.pickup' } else { 'cabin.feather.pickup' }
                $nodes += "item_id = `"$id`"`npickup_response = `"$response`"`n"
            }
            if ($id -eq 'door') { $nodes += "destination_room = `"corridor`"`nentry_x = 94.0`n" }
            if ($id -eq 'return') { $nodes += "destination_room = `"cabin`"`nentry_x = 550.0`n" }
            # Riproduce la scelta del pannello originale basata sulle classi people/exit/obj del markup.
            $kind = if ($attrs -match '\bpeople\b') { 'mouth' } elseif ($attrs -match '\bexit\b') { 'exit' } else { 'hand' }
            $nodes += "interaction_kind = `"$kind`"`n"
            $im.Dispose()
        }
        # Il figlio Visual separa la grafica dai dati dell'hotspot e si allinea all'angolo superiore sinistro.
        $spriteType = if ($isAnimated) { 'AnimatedSprite2D' } else { 'Sprite2D' }
        $nodes += "`n[node name=`"Visual`" type=`"$spriteType`" parent=`"$nodeName`"]`ncentered = false`n"
        if ($isAnimated) { $nodes += "sprite_frames = ExtResource(`"$nodeName`")`nautoplay = `"default`"`n" }
        else { $nodes += "texture = ExtResource(`"$nodeName`")`n" }
        # Le porte specchiate nel CSS mantengono lo stesso orientamento nella nuova scena.
        if ($obj.Groups[4].Value -match 'flipX') { $nodes += "flip_h = true`n" }
        $nodes += "`n"
    }
    # Scrive la scena completa in UTF-8; +1 conta la risorsa principale della scena oltre alle esterne.
    Set-Content -LiteralPath (Join-Path $projectDir "scenes/rooms/$($room[0]).tscn") -Value "[gd_scene load_steps=$($resourceCount+1) format=3]`n`n$resources`n$nodes" -Encoding utf8
}
Write-Output 'Asset grafici originali, animazioni e scene importati.'
