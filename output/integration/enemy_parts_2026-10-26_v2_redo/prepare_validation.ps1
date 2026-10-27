$ErrorActionPreference='Stop'
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$redo=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v2_redo'
$validation=Join-Path $redo 'validation_project'
$previous=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v1\validation_project'
New-Item -ItemType Directory -Path $validation -Force|Out-Null
$scene=Get-Content -LiteralPath (Join-Path $root 'scenes\enemy\enemy_spine.tscn') -Raw
foreach($match in [regex]::Matches($scene,'path="(res://[^"]+\.png)"')){
 $relative=$match.Groups[1].Value.Substring(6).Replace('/','\')
 $target=Join-Path $validation $relative
 New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force|Out-Null
 Copy-Item -LiteralPath (Join-Path $root $relative) -Destination $target -Force
}
foreach($part in Get-ChildItem -LiteralPath (Join-Path $redo 'parts') -Filter '*.png' -File){
 Copy-Item -LiteralPath $part.FullName -Destination (Join-Path $validation ('asset\Enemies\sample\images\'+$part.Name)) -Force
}
$scene=[regex]::Replace($scene,' uid="uid://[^"]+"','')
$sceneFolder=Join-Path $validation 'scenes\enemy'
New-Item -ItemType Directory -Path $sceneFolder -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $sceneFolder 'enemy_spine.tscn'),$scene,[Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $previous 'project.godot') -Destination (Join-Path $validation 'project.godot') -Force
$capture=Get-Content -LiteralPath (Join-Path $previous 'final_capture.gd') -Raw
$capture=$capture.Replace('enemy_parts_2026-10-26_v1/','enemy_parts_2026-10-26_v2_redo/').Replace('candidate/','parts/')
[IO.File]::WriteAllText((Join-Path $validation 'final_capture.gd'),$capture,[Text.UTF8Encoding]::new($false))
'Prepared isolated validation using exact-size redraws; production textures not changed yet.'
