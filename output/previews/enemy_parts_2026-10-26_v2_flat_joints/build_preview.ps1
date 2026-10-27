$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$previewRoot='D:\Godot Project\soujourn--echoes-of-the-soul\output\previews\enemy_parts_2026-10-26_v2_flat_joints'
$partsDir=Join-Path $previewRoot 'parts'
New-Item -ItemType Directory -Path $partsDir -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $previewRoot '.gdignore'),'')
$sourcePath='C:\Users\xuank\.codex\generated_images\01a1722e-0438-7060-84ea-76648f36bf4e\exec-f640887a-8c52-4d4c-adb7-d558842ad54a.png'
$names=@('left palm','right palm','right bicep','head','tail','body','left hand','right hand','lef leg','right leg')
$source=[Drawing.Bitmap]::new($sourcePath)
$records=@()
try {
  for($i=0;$i -lt $names.Count;$i++){
    $col=$i%5; $row=[int][Math]::Floor($i/5)
    $x0=[int][Math]::Floor($col*$source.Width/5.0); $x1=[int][Math]::Floor(($col+1)*$source.Width/5.0)
    $y0=[int][Math]::Floor($row*$source.Height/2.0); $y1=[int][Math]::Floor(($row+1)*$source.Height/2.0)
    $minX=$x1;$minY=$y1;$maxX=-1;$maxY=-1;$blackCount=0
    for($yy=$y0;$yy -lt $y1;$yy++){for($xx=$x0;$xx -lt $x1;$xx++){
      $pixel=$source.GetPixel($xx,$yy)
      if($pixel.A -gt 8){
        if($xx -lt $minX){$minX=$xx};if($yy -lt $minY){$minY=$yy}
        if($xx -gt $maxX){$maxX=$xx};if($yy -gt $maxY){$maxY=$yy}
        if($pixel.A -ge 240 -and $pixel.R -le 2 -and $pixel.G -le 2 -and $pixel.B -le 2){$blackCount++}
      }
    }}
    if($maxX -lt 0){throw ('Empty cutout: '+$names[$i])}
    if($blackCount -eq 0){throw ('No solid black joint in '+$names[$i])}
    $cropW=$maxX-$minX+1;$cropH=$maxY-$minY+1
    $cutout=[Drawing.Bitmap]::new($cropW+24,$cropH+24,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cg=[Drawing.Graphics]::FromImage($cutout)
    try{
      $cg.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
      $cg.Clear([Drawing.Color]::Transparent)
      $cg.DrawImage($source,[Drawing.Rectangle]::new(12,12,$cropW,$cropH),[Drawing.Rectangle]::new($minX,$minY,$cropW,$cropH),[Drawing.GraphicsUnit]::Pixel)
      $cutout.Save((Join-Path $partsDir ($names[$i]+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    }finally{$cg.Dispose();$cutout.Dispose()}
    $records += [pscustomobject]@{file=$names[$i]+'.png';source_rect=@($minX,$minY,$cropW,$cropH);solid_black_pixels=$blackCount}
  }
}finally{$source.Dispose()}
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $previewRoot 'parts_atlas_transparent.png')
$board=[Drawing.Bitmap]::new(3000,1800,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bg=[Drawing.Graphics]::FromImage($board)
$font=[Drawing.Font]::new('Segoe UI',28,[Drawing.FontStyle]::Regular)
$brush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255,240,241,244))
try{
  $bg.Clear([Drawing.Color]::FromArgb(255,62,65,72))
  $bg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  for($i=0;$i -lt $names.Count;$i++){
    $piece=[Drawing.Bitmap]::new((Join-Path $partsDir ($names[$i]+'.png')))
    try{
      $col=$i%5;$row=[int][Math]::Floor($i/5)
      $scale=[Math]::Min(510.0/$piece.Width,710.0/$piece.Height)
      $w=[int][Math]::Round($piece.Width*$scale);$h=[int][Math]::Round($piece.Height*$scale)
      $x=$col*600+[int]((600-$w)/2);$y=$row*900+40+[int]((710-$h)/2)
      $bg.DrawImage($piece,[Drawing.Rectangle]::new($x,$y,$w,$h))
      $bg.DrawString(($names[$i]+'.png'),$font,$brush,[single]($col*600+32),[single]($row*900+810))
    }finally{$piece.Dispose()}
  }
  $board.Save((Join-Path $previewRoot 'parts_preview_labeled.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$bg.Dispose();$board.Dispose();$font.Dispose();$brush.Dispose()}
$records|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $previewRoot 'parts_manifest.json') -Encoding utf8
$originalHashes=Get-Content -LiteralPath 'D:\Godot Project\soujourn--echoes-of-the-soul\output\previews\enemy_parts_2026-10-26_v1\original_hashes.json' -Raw|ConvertFrom-Json
foreach($entry in $originalHashes){if((Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -ne $entry.Hash){throw ('Original changed: '+$entry.Path)}}
if(@(Get-ChildItem -LiteralPath $partsDir -Filter '*.png').Count -ne 10){throw 'Expected 10 parts.'}
$records|Select-Object file,solid_black_pixels|ConvertTo-Json -Compress
'Original game images unchanged.'

