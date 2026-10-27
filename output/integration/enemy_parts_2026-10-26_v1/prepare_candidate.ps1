$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$workspace='D:\Godot Project\soujourn--echoes-of-the-soul'
$work=Join-Path $workspace 'output\integration\enemy_parts_2026-10-26_v1'
$approved=Join-Path $workspace 'output\previews\enemy_parts_2026-10-26_v2_flat_joints\parts'
$oldDir=Join-Path $workspace 'asset\Enemies\sample\images'
$candidate=Join-Path $work 'candidate'
$backup=Join-Path $work 'originals'
$validation=Join-Path $work 'validation_project'
foreach($dir in @($work,$candidate,$backup,$validation)){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
[IO.File]::WriteAllText((Join-Path $work '.gdignore'),'')
if(-not(Test-Path -LiteralPath (Join-Path $work 'before_hashes.json'))){
  Get-ChildItem -LiteralPath $oldDir -File|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $backup $_.Name)}
  $snapshots=@(Get-ChildItem -LiteralPath $oldDir -File|Get-FileHash -Algorithm SHA256|Select-Object Path,Hash)
  $snapshots+=Get-FileHash -LiteralPath (Join-Path $workspace 'scenes\enemy\enemy_spine.tscn') -Algorithm SHA256|Select-Object Path,Hash
  $snapshots|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $work 'before_hashes.json') -Encoding utf8
}
function Get-Similarity([double[]]$s1,[double[]]$s2,[double[]]$d1,[double[]]$d2){
  $sx=$s2[0]-$s1[0];$sy=$s2[1]-$s1[1];$dx=$d2[0]-$d1[0];$dy=$d2[1]-$d1[1]
  $den=$sx*$sx+$sy*$sy
  $a=($dx*$sx+$dy*$sy)/$den;$b=($dy*$sx-$dx*$sy)/$den
  return @($a,$b,(-$b),$a,($d1[0]-$a*$s1[0]+$b*$s1[1]),($d1[1]-$b*$s1[0]-$a*$s1[1]))
}
function Get-Affine([double[]]$s1,[double[]]$s2,[double[]]$s3,[double[]]$d1,[double[]]$d2,[double[]]$d3){
  $ux=$s2[0]-$s1[0];$uy=$s2[1]-$s1[1];$vx=$s3[0]-$s1[0];$vy=$s3[1]-$s1[1]
  $pu=$d2[0]-$d1[0];$qu=$d2[1]-$d1[1];$pv=$d3[0]-$d1[0];$qv=$d3[1]-$d1[1]
  $den=$ux*$vy-$uy*$vx
  $a=($pu*$vy-$pv*$uy)/$den;$c=($pv*$ux-$pu*$vx)/$den
  $b=($qu*$vy-$qv*$uy)/$den;$d=($qv*$ux-$qu*$vx)/$den
  return @($a,$b,$c,$d,($d1[0]-$a*$s1[0]-$c*$s1[1]),($d1[1]-$b*$s1[0]-$d*$s1[1]))
}
$config=@(
  @{name='body';mode='fit'},
  @{name='head';s1=@(35,239);s2=@(220,350);s3=@(100,120);d1=@(17,80);d2=@(88,155);d3=@(46,20)},
  @{name='left hand';s1=@(56,68);s2=@(145,356);d1=@(81.5,28);d2=@(37.5,183)},
  @{name='right hand';s1=@(238,48);s2=@(40,235);d1=@(129.5,12.5);d2=@(39.5,123.5)},
  @{name='right bicep';s1=@(239,153);s2=@(39,235);d1=@(114,48);d2=@(42,74)},
  @{name='left palm';s1=@(239,47);s2=@(130,118);d1=@(136.14,30.02);d2=@(75,40)},
  @{name='right palm';s1=@(239,48);s2=@(127,131);d1=@(125.76,23.34);d2=@(69,42.5)},
  @{name='lef leg';s1=@(207,86);s2=@(90,178);s3=@(186,330);d1=@(63.5,79.5);d2=@(45,149);d3=@(130,209)},
  @{name='right leg';s1=@(39,103);s2=@(151,353);d1=@(83,39.5);d2=@(100,177)},
  @{name='tail';s1=@(31,150);s2=@(230,28);s3=@(246,240);d1=@(48.5,62);d2=@(315,24);d3=@(345,209)}
)
$config|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $work 'alignment_config.json') -Encoding utf8
$padding=48
$report=@()
foreach($spec in $config){
  $src=[Drawing.Bitmap]::new((Join-Path $approved ($spec.name+'.png')))
  $old=[Drawing.Bitmap]::new((Join-Path $backup ($spec.name+'.png')))
  try{
    $w=$old.Width;$h=$old.Height
    if($spec.mode -eq 'fit'){$m=@(($w/[double]$src.Width),0,0,($h/[double]$src.Height),0,0)}
    elseif($spec.ContainsKey('s3')){$m=Get-Affine $spec.s1 $spec.s2 $spec.s3 $spec.d1 $spec.d2 $spec.d3}
    else{$m=Get-Similarity $spec.s1 $spec.s2 $spec.d1 $spec.d2}
    $dest=[Drawing.Bitmap]::new($w+2*$padding,$h+2*$padding,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g=[Drawing.Graphics]::FromImage($dest)
    $attributes=[Drawing.Imaging.ImageAttributes]::new()
    try{
      $g.Clear([Drawing.Color]::Transparent)
      $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
      $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
      $points=[Drawing.PointF[]]@(
       [Drawing.PointF]::new($m[4]+$padding,$m[5]+$padding),
       [Drawing.PointF]::new($m[0]*$src.Width+$m[4]+$padding,$m[1]*$src.Width+$m[5]+$padding),
       [Drawing.PointF]::new($m[2]*$src.Height+$m[4]+$padding,$m[3]*$src.Height+$m[5]+$padding)
      )
      $g.DrawImage($src,$points,[Drawing.RectangleF]::new(0,0,$src.Width,$src.Height),[Drawing.GraphicsUnit]::Pixel,$attributes)
      $dest.Save((Join-Path $candidate ($spec.name+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    }finally{$g.Dispose();$dest.Dispose();$attributes.Dispose()}
    $report+=[pscustomobject]@{file=$spec.name+'.png';old_size=@($w,$h);new_size=@(($w+96),($h+96));center_padding=48;transform=$m}
  }finally{$src.Dispose();$old.Dispose()}
}
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'alignment_manifest.json') -Encoding utf8
$sceneText=Get-Content -LiteralPath (Join-Path $workspace 'scenes\enemy\enemy_spine.tscn') -Raw
$textureMatches=[regex]::Matches($sceneText,'path="(res://[^"]+\.png)"')
foreach($match in $textureMatches){
 $relative=$match.Groups[1].Value.Substring(6).Replace('/','\')
 $target=Join-Path $validation $relative
 New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force|Out-Null
 Copy-Item -LiteralPath (Join-Path $workspace $relative) -Destination $target
}
$validationScene=Join-Path $validation 'scenes\enemy\enemy_spine.tscn'
New-Item -ItemType Directory -Path (Split-Path -Parent $validationScene) -Force|Out-Null
$sceneText=[regex]::Replace($sceneText,' uid="uid://[^"]+"','')
[IO.File]::WriteAllText($validationScene,$sceneText,[Text.UTF8Encoding]::new($false))
@'
config_version=5
[application]
config/name="Codex Enemy Art Validation"
config/use_custom_user_dir=true
config/custom_user_dir="CodexEnemyArt20261026"
[display]
window/size/viewport_width=64
window/size/viewport_height=64
window/size/initial_position_type=0
window/size/initial_position=Vector2i(-4000,-4000)
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
'@|Set-Content -LiteralPath (Join-Path $validation 'project.godot') -Encoding utf8
$report|Select-Object file,old_size,new_size|ConvertTo-Json -Compress -Depth 4

