$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$old=Join-Path $root 'output\previews\enemy_attack2_2026-10-27_v2_arm_inward'
$work=Join-Path $root 'output\previews\enemy_attack2_2026-10-27_v3_long_inward_arm'
$meta=Get-Content -LiteralPath (Join-Path $work 'generation_source.json') -Raw|ConvertFrom-Json
$layout=Get-Content -LiteralPath (Join-Path $old 'layout_manifest.json') -Raw|ConvertFrom-Json
New-Item -ItemType Directory -Path (Join-Path $work 'frames'),(Join-Path $work 'high_res') -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $work '.gdignore'),'')
Copy-Item -LiteralPath (Join-Path $old 'layout_manifest.json'),(Join-Path $old 'source_hashes.json') -Destination $work -Force
foreach($name in @('frame_1.png','frame_3.png')){Copy-Item -LiteralPath (Join-Path (Join-Path $old 'frames') $name) -Destination (Join-Path (Join-Path $work 'frames') $name) -Force}
Copy-Item -LiteralPath $meta.generated_path -Destination (Join-Path $work 'high_res\frame_2.png') -Force
$src=[Drawing.Bitmap]::new($meta.generated_path)
$generated=[Drawing.Bitmap]::new(1274,704,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[Drawing.Graphics]::FromImage($generated)
try{
 $g.Clear([Drawing.Color]::Transparent)
 $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
 $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 $g.DrawImage($src,[Drawing.Rectangle]::new(0,0,1274,704),0,0,$src.Width,$src.Height,[Drawing.GraphicsUnit]::Pixel)
}finally{$g.Dispose();$src.Dispose()}
$frame=[Drawing.Bitmap]::new((Join-Path $old 'frames\frame_2.png'))
# Integrate only the generated arm region. Keep every pixel outside it from v2,
# including the slash crescent and the rest of the body; never reposition the cell.
$rx=420;$ry=490;$rw=400;$rh=190;$feather=6
try{
 for($y=$ry;$y -lt $ry+$rh;$y++){for($x=$rx;$x -lt $rx+$rw;$x++){
  $distance=[Math]::Min([Math]::Min($x-$rx,$rx+$rw-1-$x),[Math]::Min($y-$ry,$ry+$rh-1-$y))
  if($distance -le 0){continue}
  $new=$generated.GetPixel($x,$y)
  if($distance -ge $feather){$frame.SetPixel($x,$y,$new);continue}
  $oldPixel=$frame.GetPixel($x,$y);$t=$distance/[double]$feather
  $oa=$oldPixel.A/255.0;$na=$new.A/255.0;$a=(1-$t)*$oa+$t*$na
  if($a -le 0){$frame.SetPixel($x,$y,[Drawing.Color]::Transparent);continue}
  $red=[int][Math]::Round(((1-$t)*$oa*$oldPixel.R+$t*$na*$new.R)/$a)
  $green=[int][Math]::Round(((1-$t)*$oa*$oldPixel.G+$t*$na*$new.G)/$a)
  $blue=[int][Math]::Round(((1-$t)*$oa*$oldPixel.B+$t*$na*$new.B)/$a)
  $alpha=[int][Math]::Round($a*255)
  $frame.SetPixel($x,$y,[Drawing.Color]::FromArgb($alpha,$red,$green,$blue))
 }}
 $frame.Save((Join-Path $work 'frames\frame_2.png'),[Drawing.Imaging.ImageFormat]::Png)
 $sheet=[Drawing.Bitmap]::new((Join-Path $old 'attack2.png'))
 $sg=[Drawing.Graphics]::FromImage($sheet)
 try{
  $slot=[Drawing.RectangleF]::new($layout.logical_frame_width,0,$layout.logical_frame_width,704)
  $sg.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
  $sg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $sg.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $sg.SetClip($slot)
  $sg.DrawImage($frame,$slot,[Drawing.RectangleF]::new(0,0,1274,704),[Drawing.GraphicsUnit]::Pixel)
  $sheet.Save((Join-Path $work 'attack2.png'),[Drawing.Imaging.ImageFormat]::Png)
 }finally{$sg.Dispose();$sheet.Dispose()}
}finally{$frame.Dispose();$generated.Dispose()}
$font=[Drawing.Font]::new('Arial',28);$pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(150,190,215),3)
try{
 $sheet=[Drawing.Bitmap]::new((Join-Path $work 'attack2.png'))
 $out=[Drawing.Bitmap]::new(3823,768,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[Drawing.Graphics]::FromImage($out)
 try{
  $g.Clear([Drawing.Color]::FromArgb(86,96,111))
  $g.DrawImage($sheet,[Drawing.Rectangle]::new(0,58,3823,704),0,0,3823,704,[Drawing.GraphicsUnit]::Pixel)
  for($i=0;$i -lt 3;$i++){$x=$i*$layout.logical_frame_width;$g.DrawString(('Preview — ô '+($i+1)),$font,[Drawing.Brushes]::White,[single]($x+18),[single]10);if($i -gt 0){$g.DrawLine($pen,[single]$x,0,[single]$x,767)}}
  $out.Save((Join-Path $work 'preview.png'),[Drawing.Imaging.ImageFormat]::Png)
 }finally{$g.Dispose();$out.Dispose();$sheet.Dispose()}
}finally{$font.Dispose();$pen.Dispose()}
$font=[Drawing.Font]::new('Arial',22)
try{
 foreach($mode in @('arm_detail','arm_comparison')){
  $cols=1;if($mode -eq 'arm_comparison'){$cols=2}
  $out=[Drawing.Bitmap]::new((1040*$cols),680,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[Drawing.Graphics]::FromImage($out)
  try{
   $g.Clear([Drawing.Color]::FromArgb(86,96,111));$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   for($i=0;$i -lt $cols;$i++){
    if($cols -eq 2 -and $i -eq 0){$path=Join-Path $old 'frames\frame_2.png';$label='Trước — tay gập sát ngực'}
    else{$path=Join-Path $work 'frames\frame_2.png';$label='Sửa — tay dài ngay dưới hàm, vuốt khuất'}
    $b=[Drawing.Bitmap]::new($path)
    try{$g.DrawString($label,$font,[Drawing.Brushes]::White,[single]($i*1040+20),[single]10);$g.DrawImage($b,[Drawing.RectangleF]::new(($i*1040),50,1040,628),[Drawing.RectangleF]::new(350,390,520,314),[Drawing.GraphicsUnit]::Pixel)}finally{$b.Dispose()}
   }
   $out.Save((Join-Path $work ($mode+'.png')),[Drawing.Imaging.ImageFormat]::Png)
  }finally{$g.Dispose();$out.Dispose()}
 }
}finally{$font.Dispose()}
foreach($name in @('frame_1.png','frame_3.png')){if((Get-FileHash -LiteralPath (Join-Path (Join-Path $old 'frames') $name)).Hash -ne (Get-FileHash -LiteralPath (Join-Path (Join-Path $work 'frames') $name)).Hash){throw ('Unchanged frame differs: '+$name)}}
$before=Get-Content -LiteralPath (Join-Path $work 'source_hashes.json') -Raw|ConvertFrom-Json
foreach($entry in $before){if((Get-FileHash -LiteralPath $entry.Path).Hash -ne $entry.Hash){throw ('Game asset changed: '+$entry.Path)}}
[pscustomobject]@{status='preview_only_pending_approval';sheet_width=3823;sheet_height=704;hframes=3;vframes=1;changed_frame=1;frames_1_and_3_byte_identical=$true;arm_edit_region=@($rx,$ry,$rw,$rh);outside_arm_region_preserved_from_previous_preview=$true;game_assets_unchanged=$true;preview_sha256=(Get-FileHash -LiteralPath (Join-Path $work 'attack2.png')).Hash}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $work 'preview_validation.json') -Encoding utf8
'PREVIEW_READY: longer inward arm; fixed 3823x704 sheet; frames 1/3 and game unchanged.'
