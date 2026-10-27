$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$work=Join-Path $root 'output\previews\enemy_attack1_2026-10-27_v1'
$manifest=Get-Content -LiteralPath (Join-Path $work 'generation_manifest.json') -Raw|ConvertFrom-Json
$frames=Join-Path $work 'frames'
New-Item -ItemType Directory -Path $frames -Force|Out-Null
$checks=@()
foreach($m in $manifest){
 $src=[Drawing.Bitmap]::new((Join-Path (Join-Path $work 'high_res') $m.file))
 $dest=[Drawing.Bitmap]::new($m.original_width,$m.original_height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($dest)
 try{
  $g.Clear([Drawing.Color]::Transparent)
  $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  # Whole-canvas resolution conversion only. No crop, rotation or object repositioning.
  $g.DrawImage($src,[Drawing.Rectangle]::new(0,0,$dest.Width,$dest.Height),0,0,$src.Width,$src.Height,[Drawing.GraphicsUnit]::Pixel)
  $dest.Save((Join-Path $frames $m.file),[Drawing.Imaging.ImageFormat]::Png)
  $clear=0;$opaque=0
  for($y=0;$y -lt $dest.Height;$y++){for($x=0;$x -lt $dest.Width;$x++){
   $a=$dest.GetPixel($x,$y).A
   if($a -eq 0){$clear++};if($a -eq 255){$opaque++}
  }}
  if($clear -eq 0 -or $opaque -eq 0){throw ('Unexpected alpha in '+$m.file)}
  $checks+=[pscustomobject]@{file=$m.file;width=$dest.Width;height=$dest.Height;high_res_width=$src.Width;high_res_height=$src.Height;transparent_pixels=$clear;opaque_pixels=$opaque;status='preview_only_pending_approval'}
 }finally{$src.Dispose();$dest.Dispose();$g.Dispose()}
}
$rowHeights=@();$totalHeight=0
foreach($m in $manifest){$h=[int][Math]::Ceiling($m.original_height*860.0/$m.original_width)+68;$rowHeights+=$h;$totalHeight+=$h}
$sheet=[Drawing.Bitmap]::new(1800,$totalHeight,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sg=[Drawing.Graphics]::FromImage($sheet);$font=[Drawing.Font]::new('Arial',17)
try{
 $sg.Clear([Drawing.Color]::FromArgb(46,50,58));$sg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $top=0
 for($i=0;$i -lt $manifest.Count;$i++){
  $m=$manifest[$i];$displayHeight=[int][Math]::Round($m.original_height*860.0/$m.original_width)
  for($col=0;$col -lt 2;$col++){
   if($col -eq 0){$p=Join-Path $root ('asset\Enemies\sample\attack\'+$m.file);$label='Ảnh cũ — '+$m.file}
   else{$p=Join-Path $frames $m.file;$label='Preview mới — '+$m.file}
   $b=[Drawing.Bitmap]::new($p)
   try{$sg.DrawString($label,$font,[Drawing.Brushes]::White,[single]($col*900+20),[single]($top+12));$sg.DrawImage($b,[Drawing.Rectangle]::new(($col*900+20),($top+48),860,$displayHeight))}finally{$b.Dispose()}
  }
  $top+=$rowHeights[$i]
 }
 $sheet.Save((Join-Path $work 'comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$sheet.Dispose();$sg.Dispose();$font.Dispose()}
$sources=Get-Content -LiteralPath (Join-Path $work 'source_hashes.json') -Raw|ConvertFrom-Json
foreach($record in $sources){if((Get-FileHash -LiteralPath $record.Path).Hash -ne $record.Hash){throw ('Source asset changed: '+$record.Path)}}
[pscustomobject]@{status='preview_only_pending_approval';frames=$checks;production_assets_unchanged=$true;verified_source_files=$sources.Count;runtime_animation_tested=$false}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'preview_validation.json') -Encoding utf8
'PREVIEW_READY: 3 transparent PNGs in original canvas sizes; production assets unchanged.'
