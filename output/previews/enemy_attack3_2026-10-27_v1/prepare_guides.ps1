$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$work=Join-Path $root 'output\previews\enemy_attack3_2026-10-27_v1'
if(Test-Path -LiteralPath (Join-Path $work 'source_hashes.json')){throw 'Preview initialized; inspect existing data first'}
New-Item -ItemType Directory -Path (Join-Path $work 'pose_guides'),(Join-Path $work 'source_frames') -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $work '.gdignore'),'')
$path=Join-Path $root 'asset\Enemies\sample\attack\attack3.png'
$src=[Drawing.Bitmap]::new($path);$frames=@()
try{
 $fw=$src.Width/3.0;$ww=[int][Math]::Round($fw)
 for($i=0;$i -lt 3;$i++){
  $b=[Drawing.Bitmap]::new($ww,$src.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[Drawing.Graphics]::FromImage($b)
  try{
   $g.Clear([Drawing.Color]::Transparent);$g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
   $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
   $g.DrawImage($src,[Drawing.RectangleF]::new(0,0,$ww,$src.Height),[Drawing.RectangleF]::new(($i*$fw),0,$fw,$src.Height),[Drawing.GraphicsUnit]::Pixel)
   $name='frame_'+($i+1)+'.png';$b.Save((Join-Path (Join-Path $work 'source_frames') $name),[Drawing.Imaging.ImageFormat]::Png)
   $guide=[Drawing.Bitmap]::new($ww,$src.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$gg=[Drawing.Graphics]::FromImage($guide)
   try{$gg.Clear([Drawing.Color]::FromArgb(100,110,124));$gg.DrawImage($b,[Drawing.Rectangle]::new(0,0,$ww,$src.Height),0,0,$ww,$src.Height,[Drawing.GraphicsUnit]::Pixel);$guide.Save((Join-Path (Join-Path $work 'pose_guides') $name),[Drawing.Imaging.ImageFormat]::Png)}finally{$gg.Dispose();$guide.Dispose()}
   $frames+=[pscustomobject]@{frame=$i;file=$name;source_x=$i*$fw;source_y=0;source_width=$fw;source_height=$src.Height;working_width=$ww;working_height=$src.Height}
  }finally{$g.Dispose();$b.Dispose()}
 }
 [pscustomobject]@{sheet_width=$src.Width;sheet_height=$src.Height;hframes=3;vframes=1;logical_frame_width=$fw;frames=$frames;game_asset=(Get-FileHash -LiteralPath $path|Select-Object Path,Hash)}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'layout_manifest.json') -Encoding utf8
 'CANVAS='+$src.Width+'x'+$src.Height+'; CELL='+$fw+'x'+$src.Height
}finally{$src.Dispose()}
$paths=@(Get-ChildItem -LiteralPath (Join-Path $root 'asset\Enemies\sample\attack') -File|Select-Object -ExpandProperty FullName)
$paths+=Join-Path $root 'scenes\enemy\enemy_spine.tscn'
$paths|ForEach-Object {Get-FileHash -LiteralPath $_|Select-Object Path,Hash}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $work 'source_hashes.json') -Encoding utf8
$scene=Get-Content -LiteralPath (Join-Path $root 'scenes\enemy\enemy_spine.tscn') -Raw
$start=$scene.IndexOf('resource_name = "attack3"');$end=$scene.IndexOf('[sub_resource',$start+1)
if($end -lt 0){$end=$scene.Length}
$clip=$scene.Substring($start,$end-$start)
[IO.File]::WriteAllText((Join-Path $work 'original_animation.txt'),$clip,[Text.UTF8Encoding]::new($false))
$clip
