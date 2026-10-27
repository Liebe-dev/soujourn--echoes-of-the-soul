$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$preview=Join-Path $root 'output\previews\enemy_attack2_2026-10-27_v3_long_inward_arm'
$work=Join-Path $root 'output\integration\enemy_attack2_2026-10-27_v3_long_inward_arm'
$backup=Join-Path $work 'originals'
$source=Join-Path $preview 'attack2.png'
$target=Join-Path $root 'asset\Enemies\sample\attack\attack2.png'
$validation=Get-Content -LiteralPath (Join-Path $preview 'preview_validation.json') -Raw|ConvertFrom-Json
$layout=Get-Content -LiteralPath (Join-Path $preview 'layout_manifest.json') -Raw|ConvertFrom-Json
$approvedHash=(Get-FileHash -LiteralPath $source).Hash
if($approvedHash -ne $validation.preview_sha256){throw 'Approved preview changed'}
if($validation.sheet_width -ne 3823 -or $validation.sheet_height -ne 704 -or $validation.hframes -ne 3 -or $validation.vframes -ne 1){throw 'Approved sheet layout mismatch'}
$targetHash=(Get-FileHash -LiteralPath $target).Hash
if($targetHash -ne $layout.game_asset.Hash -and $targetHash -ne $approvedHash){throw 'Current game sheet changed since preview'}
$a=[Drawing.Bitmap]::new($source);$b=[Drawing.Bitmap]::new($target)
try{if($a.Width -ne 3823 -or $a.Height -ne 704 -or $a.Size -ne $b.Size){throw 'PNG canvas size mismatch'}}finally{$a.Dispose();$b.Dispose()}
New-Item -ItemType Directory -Path $backup -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $work '.gdignore'),'')
$saved=Join-Path $backup 'attack2.png'
if(Test-Path -LiteralPath $saved){
 if((Get-FileHash -LiteralPath $saved).Hash -ne $layout.game_asset.Hash){throw 'Existing original backup mismatch'}
}else{
 if($targetHash -ne $layout.game_asset.Hash){throw 'Already installed without original backup; inspect before continuing'}
 Copy-Item -LiteralPath $target -Destination $saved
}
if(Test-Path -LiteralPath ($target+'.import')){Copy-Item -LiteralPath ($target+'.import') -Destination (Join-Path $backup 'attack2.png.import') -Force}
$keepPaths=@(Get-ChildItem -LiteralPath (Split-Path -Parent $target) -File|Where-Object {$_.FullName -ne $target}|Select-Object -ExpandProperty FullName)
$keepPaths+=Join-Path $root 'scenes\enemy\enemy_spine.tscn'
$keep=@($keepPaths|ForEach-Object {Get-FileHash -LiteralPath $_|Select-Object Path,Hash})
$keep|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $work 'unchanged_before.json') -Encoding utf8
if($targetHash -ne $approvedHash){Copy-Item -LiteralPath $source -Destination $target -Force}
$installedHash=(Get-FileHash -LiteralPath $target).Hash
if($installedHash -ne $approvedHash){throw 'Installed PNG differs from approved preview'}
foreach($entry in $keep){if((Get-FileHash -LiteralPath $entry.Path).Hash -ne $entry.Hash){throw ('Unintended change: '+$entry.Path)}}
[pscustomobject]@{
 status='installed'
 approval='User: duyệt, thay đi'
 file=$target
 source=$source
 width=3823
 height=704
 hframes=3
 vframes=1
 sha256=$installedHash
 matches_approved_preview=$true
 copied_verbatim=$true
 backup=$saved
 scene_and_animation_unchanged=$true
 import_sidecar_unchanged=$true
 unchanged_other_files=$keep.Count
}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $work 'installation_result.json') -Encoding utf8
'INSTALLED attack2.png; EXACT_APPROVED_V3; CANVAS=3823x704; THREE_X_FRAMES; SCENE_AND_IMPORT_UNCHANGED'
