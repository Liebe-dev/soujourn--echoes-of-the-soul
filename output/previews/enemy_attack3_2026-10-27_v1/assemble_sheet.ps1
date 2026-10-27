$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$work=Join-Path $root 'output\previews\enemy_attack3_2026-10-27_v1'
$layout=Get-Content -LiteralPath (Join-Path $work 'layout_manifest.json') -Raw|ConvertFrom-Json
$sources=Get-Content -LiteralPath (Join-Path $work 'generation_manifest.json') -Raw|ConvertFrom-Json
New-Item -ItemType Directory -Path (Join-Path $work 'high_res'),(Join-Path $work 'frames') -Force|Out-Null
$sheet=[Drawing.Bitmap]::new($layout.sheet_width,$layout.sheet_height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sg=[Drawing.Graphics]::FromImage($sheet)
$report=@()
try{
 $sg.Clear([Drawing.Color]::Transparent)
 $sg.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
 $sg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $sg.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 foreach($f in $layout.frames){
  $m=$sources|Where-Object {$_.file -eq $f.file}
  $raw=Join-Path (Join-Path $work 'high_res') $f.file
  Copy-Item -LiteralPath $m.generated_path -Destination $raw -Force
  $src=[Drawing.Bitmap]::new($raw)
  $frame=[Drawing.Bitmap]::new($f.working_width,$f.working_height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g=[Drawing.Graphics]::FromImage($frame)
  try{
   $g.Clear([Drawing.Color]::Transparent)
   $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
   $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
   # Convert the complete generation canvas; never trim or center its alpha bounds.
   $g.DrawImage($src,[Drawing.Rectangle]::new(0,0,$frame.Width,$frame.Height),0,0,$src.Width,$src.Height,[Drawing.GraphicsUnit]::Pixel)
   $frame.Save((Join-Path (Join-Path $work 'frames') $f.file),[Drawing.Imaging.ImageFormat]::Png)
   $state=$sg.Save()
   try{
    $slot=[Drawing.RectangleF]::new($f.source_x,0,$f.source_width,$f.source_height)
    $sg.SetClip($slot)
    $sg.DrawImage($frame,$slot,[Drawing.RectangleF]::new(0,0,$frame.Width,$frame.Height),[Drawing.GraphicsUnit]::Pixel)
   }finally{$sg.Restore($state)}
   $report+=[pscustomobject]@{frame=$f.frame;file=$f.file;slot_x=$f.source_x;slot_width=$f.source_width;slot_height=$f.source_height;manual_translation=@(0,0);rotation_degrees=0;alpha_autocrop=$false;object_auto_center=$false;high_res_size=@($src.Width,$src.Height)}
  }finally{$g.Dispose();$frame.Dispose();$src.Dispose()}
 }
 $sheet.Save((Join-Path $work 'attack3.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$sg.Dispose();$sheet.Dispose()}
$font=[Drawing.Font]::new('Arial',28)
$pen=[Drawing.Pen]::new([Drawing.Color]::FromArgb(150,190,215),3)
try{
 foreach($mode in @('preview','comparison')){
  $rows=1;if($mode -eq 'comparison'){$rows=2}
  $rowHeight=$layout.sheet_height+64
  $out=[Drawing.Bitmap]::new($layout.sheet_width,($rows*$rowHeight),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g=[Drawing.Graphics]::FromImage($out)
  try{
   $g.Clear([Drawing.Color]::FromArgb(86,96,111))
   for($row=0;$row -lt $rows;$row++){
    if($rows -eq 2 -and $row -eq 0){$path=Join-Path $root 'asset\Enemies\sample\attack\attack3.png';$prefix='Gốc'}
    else{$path=Join-Path $work 'attack3.png';$prefix='Preview mới'}
    $b=[Drawing.Bitmap]::new($path)
    try{$g.DrawImage($b,[Drawing.Rectangle]::new(0,($row*$rowHeight+58),$layout.sheet_width,$layout.sheet_height),0,0,$b.Width,$b.Height,[Drawing.GraphicsUnit]::Pixel)}finally{$b.Dispose()}
    for($i=0;$i -lt 3;$i++){
     $x=$i*$layout.logical_frame_width
     $g.DrawString(($prefix+' — ô '+($i+1)),$font,[Drawing.Brushes]::White,[single]($x+18),[single]($row*$rowHeight+10))
     if($i -gt 0){$g.DrawLine($pen,[single]$x,[single]($row*$rowHeight),[single]$x,[single](($row+1)*$rowHeight-1))}
    }
   }
   $out.Save((Join-Path $work ($mode+'.png')),[Drawing.Imaging.ImageFormat]::Png)
  }finally{$g.Dispose();$out.Dispose()}
 }
}finally{$font.Dispose();$pen.Dispose()}
$before=Get-Content -LiteralPath (Join-Path $work 'source_hashes.json') -Raw|ConvertFrom-Json
foreach($f in $before){if((Get-FileHash -LiteralPath $f.Path).Hash -ne $f.Hash){throw ('Game resource changed: '+$f.Path)}}
$check=[Drawing.Bitmap]::new((Join-Path $work 'attack3.png'))
try{if($check.Width -ne 2703 -or $check.Height -ne 931){throw 'Sheet dimensions changed'}}finally{$check.Dispose()}
[pscustomobject]@{status='preview_only_pending_approval';sheet_width=$layout.sheet_width;sheet_height=$layout.sheet_height;hframes=3;vframes=1;logical_cell_width=$layout.logical_frame_width;frames=$report;game_assets_unchanged=$true;runtime_animation_tested=$false;preview_sha256=(Get-FileHash -LiteralPath (Join-Path $work 'attack3.png')).Hash}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'preview_validation.json') -Encoding utf8
'SPRITE_SHEET_PREVIEW_READY: 2703x931; original 3 equal X slots; game unchanged.'
