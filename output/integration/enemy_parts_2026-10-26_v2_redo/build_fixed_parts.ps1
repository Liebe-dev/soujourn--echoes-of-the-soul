$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$redo=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v2_redo'
$old=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v1\originals'
$parts=Join-Path $redo 'parts'
New-Item -ItemType Directory -Path $parts -Force|Out-Null
$manifest=Get-Content -LiteralPath (Join-Path $redo 'generated_sources.json') -Raw|ConvertFrom-Json
$roots=@{
 'body.png'=@(@{x=20;y=165;r=75},@{x=110;y=202;r=55},@{x=260;y=200;r=65})
 'head.png'=@(@{x0=52;y0=55;w=47;h=133})
 'lef leg.png'=@(@{x0=0;y0=0;w=115;h=120})
 'left hand.png'=@(@{x=81.5;y=28;r=40},@{x=37.5;y=183;r=25})
 'left palm.png'=@(@{x=136.14;y=30.02;r=27})
 'right bicep.png'=@(@{x=114;y=48;r=42},@{x=42;y=74;r=40})
 'right hand.png'=@(@{x=129.5;y=12.5;r=35},@{x=39.5;y=123.5;r=25})
 'right leg.png'=@(@{x=83;y=39.5;r=40})
 'right palm.png'=@(@{x=125.76;y=23.34;r=25})
 'tail.png'=@(@{x=48.5;y=62;r=46})
}
$report=@()
foreach($m in $manifest){
 $src=[Drawing.Bitmap]::new((Join-Path (Join-Path $redo 'generated') $m.file))
 $original=[Drawing.Bitmap]::new((Join-Path $old $m.file))
 if(-not $m.full_canvas -and $src.Width -ne $src.Height){throw ('Expected square generation canvas: '+$m.file)}
 if($original.Width -ne $m.width -or $original.Height -ne $m.height){throw ('Original dimensions changed: '+$m.file)}
 $dest=[Drawing.Bitmap]::new($m.width,$m.height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $overlap=[Drawing.Bitmap]::new($m.width,$m.height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($dest)
 $attrs=[Drawing.Imaging.ImageAttributes]::new()
 try{
  $g.Clear([Drawing.Color]::Transparent)
  # Preserve only the original JOINT overlap regions in flat black.
  # No old head/armor/tail surface or non-joint silhouette is copied.
  for($py=0;$py -lt $m.height;$py++){for($px=0;$px -lt $m.width;$px++){
   $a=$original.GetPixel($px,$py).A
   if($a -eq 0){continue}
   $inside=$false
   foreach($region in $roots[$m.file]){
    if($region.ContainsKey('r')){
     if(($px-$region.x)*($px-$region.x)+($py-$region.y)*($py-$region.y) -le $region.r*$region.r){$inside=$true;break}
    }elseif($px -ge $region.x0 -and $py -ge $region.y0 -and $px -lt $region.x0+$region.w -and $py -lt $region.y0+$region.h){$inside=$true;break}
   }
   if($inside){$overlap.SetPixel($px,$py,[Drawing.Color]::FromArgb($a,0,0,0))}
  }}
  $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.DrawImageUnscaled($overlap,0,0)
  $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceOver
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $ratio=$src.Width/1024.0
  if($m.full_canvas){$crop=[Drawing.RectangleF]::new(0,0,$src.Width,$src.Height)}
  else{$crop=[Drawing.RectangleF]::new(($m.crop_x*$ratio),($m.crop_y*$ratio),($m.crop_width*$ratio),($m.crop_height*$ratio))}
  $g.DrawImage($src,[Drawing.RectangleF]::new(0,0,$m.width,$m.height),$crop,[Drawing.GraphicsUnit]::Pixel)
  $dest.Save((Join-Path $parts $m.file),[Drawing.Imaging.ImageFormat]::Png)
  $missing=0;$oldCount=0
  for($y=0;$y -lt $original.Height;$y++){for($x=0;$x -lt $original.Width;$x++){
   $a=$overlap.GetPixel($x,$y).A
   if($a -ge 128){$oldCount++;if($dest.GetPixel($x,$y).A -lt 128){$missing++}}
  }}
  if($missing -ne 0){throw ('Lost original attachment coverage: '+$m.file)}
  $report+=[pscustomobject]@{file=$m.file;width=$m.width;height=$m.height;original_size_preserved=$true;manual_rotation_degrees=0;manual_translation=@(0,0);added_padding=0;original_joint_opaque_pixels=$oldCount;missing_original_joint_coverage=$missing;method='Fixed original template frame; resolution conversion only; original joint alpha underlay in black'}
 }finally{$src.Dispose();$original.Dispose();$overlap.Dispose();$dest.Dispose();$g.Dispose();$attrs.Dispose()}
}
$report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $redo 'fixed_frame_validation.json') -Encoding utf8
$sheet=[Drawing.Bitmap]::new(1500,800,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sg=[Drawing.Graphics]::FromImage($sheet);$font=[Drawing.Font]::new('Arial',13)
try{
 $sg.Clear([Drawing.Color]::FromArgb(46,50,58))
 for($i=0;$i -lt $manifest.Count;$i++){
  $m=$manifest[$i];$b=[Drawing.Bitmap]::new((Join-Path $parts $m.file))
  try{
   $x=($i%5)*300;$y=[int][Math]::Floor($i/5)*400
   $s=[Math]::Min(270.0/$b.Width,330.0/$b.Height)
   $w=[int]($b.Width*$s);$h=[int]($b.Height*$s)
   $sg.DrawImage($b,[Drawing.Rectangle]::new(($x+(300-$w)/2),($y+(345-$h)/2),$w,$h))
   $sg.DrawString(($m.file+'  '+$m.width+'x'+$m.height),$font,[Drawing.Brushes]::White,[single]($x+12),[single]($y+365))
  }finally{$b.Dispose()}
 }
 $sheet.Save((Join-Path $redo 'parts_fixed_frame_preview.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$sheet.Dispose();$sg.Dispose();$font.Dispose()}
'FIXED_FRAMES_OK: 10 files; exact original dimensions; no shifted/rotated parts; overlap coverage preserved.'
