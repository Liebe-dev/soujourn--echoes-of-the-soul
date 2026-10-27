$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$work=Join-Path $root 'output\previews\enemy_attack2_2026-10-27_v1'
if(Test-Path -LiteralPath (Join-Path $work 'source_hashes.json')){throw 'Preview folder initialized; inspect existing data first'}
New-Item -ItemType Directory -Path (Join-Path $work 'pose_guides'),(Join-Path $work 'source_frames') -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $work '.gdignore'),'')
$path=Join-Path $root 'asset\Enemies\sample\attack\attack2.png'
$src=[Drawing.Bitmap]::new($path)
$manifest=@()
try{
 $logicalWidth=$src.Width/3.0
 $workingWidth=[int][Math]::Round($logicalWidth)
 for($i=0;$i -lt 3;$i++){
  $frame=[Drawing.Bitmap]::new($workingWidth,$src.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g=[Drawing.Graphics]::FromImage($frame)
  try{
   $g.Clear([Drawing.Color]::Transparent)
   $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
   $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
   $g.DrawImage($src,[Drawing.RectangleF]::new(0,0,$workingWidth,$src.Height),[Drawing.RectangleF]::new(($i*$logicalWidth),0,$logicalWidth,$src.Height),[Drawing.GraphicsUnit]::Pixel)
   $file='frame_'+($i+1)+'.png'
   $frame.Save((Join-Path (Join-Path $work 'source_frames') $file),[Drawing.Imaging.ImageFormat]::Png)
   $guide=[Drawing.Bitmap]::new($workingWidth,$src.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
   $gg=[Drawing.Graphics]::FromImage($guide)
   try{
    $gg.Clear([Drawing.Color]::FromArgb(100,110,124))
    $gg.DrawImage($frame,[Drawing.Rectangle]::new(0,0,$workingWidth,$src.Height),0,0,$workingWidth,$src.Height,[Drawing.GraphicsUnit]::Pixel)
    $guide.Save((Join-Path (Join-Path $work 'pose_guides') $file),[Drawing.Imaging.ImageFormat]::Png)
   }finally{$guide.Dispose();$gg.Dispose()}
   $manifest+=[pscustomobject]@{frame=$i;file=$file;source_x=$i*$logicalWidth;source_y=0;source_width=$logicalWidth;source_height=$src.Height;working_width=$workingWidth;working_height=$src.Height}
  }finally{$frame.Dispose();$g.Dispose()}
 }
 [pscustomobject]@{sheet_width=$src.Width;sheet_height=$src.Height;hframes=3;vframes=1;logical_frame_width=$logicalWidth;frames=$manifest;game_asset=(Get-FileHash -LiteralPath $path|Select-Object Path,Hash)}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'layout_manifest.json') -Encoding utf8
}finally{$src.Dispose()}
$paths=@(Get-ChildItem -LiteralPath (Join-Path $root 'asset\Enemies\sample\attack') -File|Select-Object -ExpandProperty FullName)
$paths+=Join-Path $root 'scenes\enemy\enemy_spine.tscn'
$paths|ForEach-Object {Get-FileHash -LiteralPath $_|Select-Object Path,Hash}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $work 'source_hashes.json') -Encoding utf8
'Created 3 fixed registration frames; original sprite sheet and game files unchanged.'
