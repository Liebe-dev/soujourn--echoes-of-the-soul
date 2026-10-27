$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$previewRoot = 'D:\Godot Project\soujourn--echoes-of-the-soul\output\previews\enemy_parts_2026-10-26_v1'
$atlasPath = 'C:\Users\xuank\.codex\generated_images\01a1722e-0438-7060-84ea-76648f36bf4e\exec-0fd83511-55d8-4a15-95a3-a0c401f078ef.png'
$partsDir = Join-Path $previewRoot 'parts'
New-Item -ItemType Directory -Path $partsDir -Force | Out-Null
$partSpecs = @(
  @{ name='left palm';   roi=@(0,155,330,295) },
  @{ name='right palm';  roi=@(340,155,310,300) },
  @{ name='right bicep'; roi=@(675,70,265,340) },
  @{ name='head';        roi=@(945,45,260,430) },
  @{ name='tail';        roi=@(1208,45,411,435) },
  @{ name='body';        roi=@(0,485,480,455) },
  @{ name='left hand';   roi=@(485,485,195,455) },
  @{ name='right hand';  roi=@(690,575,265,365) },
  @{ name='lef leg';     roi=@(960,480,375,485) },
  @{ name='right leg';   roi=@(1340,480,279,485) }
)
$atlas = [System.Drawing.Bitmap]::new($atlasPath)
$partRecords = @()
try {
  foreach ($partSpec in $partSpecs) {
    $r = $partSpec.roi
    $minX=$r[2]; $minY=$r[3]; $maxX=-1; $maxY=-1
    for($yy=0;$yy -lt $r[3];$yy++) {
      for($xx=0;$xx -lt $r[2];$xx++) {
        $excludeOtherPart = ($partSpec.name -eq 'tail' -and ($r[0]+$xx) -lt 1268 -and ($r[1]+$yy) -ge 340)
        if(-not $excludeOtherPart -and $atlas.GetPixel($r[0]+$xx,$r[1]+$yy).A -gt 8) {
          if($xx -lt $minX){$minX=$xx}; if($yy -lt $minY){$minY=$yy}
          if($xx -gt $maxX){$maxX=$xx}; if($yy -gt $maxY){$maxY=$yy}
        }
      }
    }
    if($maxX -lt 0){throw ('Empty part: '+$partSpec.name)}
    $cropX=$r[0]+$minX; $cropY=$r[1]+$minY
    $cropW=$maxX-$minX+1; $cropH=$maxY-$minY+1
    $sourceRect=[System.Drawing.Rectangle]::new($cropX,$cropY,$cropW,$cropH)
    $piece=[System.Drawing.Bitmap]::new($cropW+24,$cropH+24,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pieceGraphics=[System.Drawing.Graphics]::FromImage($piece)
    try {
      $pieceGraphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
      $pieceGraphics.Clear([System.Drawing.Color]::Transparent)
      $pieceGraphics.DrawImage($atlas,[System.Drawing.Rectangle]::new(12,12,$cropW,$cropH),$sourceRect,[System.Drawing.GraphicsUnit]::Pixel)
      if($partSpec.name -eq 'tail') {
        $transparentBrush=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::Transparent)
        try {
          $excludeX=12+[Math]::Max(0,1208-$cropX)
          $excludeY=12+[Math]::Max(0,340-$cropY)
          $excludeW=[Math]::Max(0,[Math]::Min($cropW,1268-$cropX))
          $excludeH=[Math]::Max(0,$piece.Height-$excludeY)
          if($excludeW -gt 0 -and $excludeH -gt 0){$pieceGraphics.FillRectangle($transparentBrush,$excludeX,$excludeY,$excludeW,$excludeH)}
        } finally {$transparentBrush.Dispose()}
      }
      $piecePath=Join-Path $partsDir ($partSpec.name+'.png')
      $piece.Save($piecePath,[System.Drawing.Imaging.ImageFormat]::Png)
    } finally {$pieceGraphics.Dispose();$piece.Dispose()}
    $oldPath=Join-Path 'D:\Godot Project\soujourn--echoes-of-the-soul\asset\Enemies\sample\images' ($partSpec.name+'.png')
    $oldBitmap=[System.Drawing.Bitmap]::new($oldPath)
    try {$oldWidth=$oldBitmap.Width;$oldHeight=$oldBitmap.Height} finally {$oldBitmap.Dispose()}
    $partRecords += [pscustomobject]@{
      file=$partSpec.name+'.png'; source_rect=@($cropX,$cropY,$cropW,$cropH)
      preview_canvas=@(($cropW+24),($cropH+24)); original_canvas=@($oldWidth,$oldHeight)
      original_sha256=(Get-FileHash -LiteralPath $oldPath -Algorithm SHA256).Hash
    }
  }
} finally {$atlas.Dispose()}

$boardWidth=3000; $boardHeight=1800
$board=[System.Drawing.Bitmap]::new($boardWidth,$boardHeight,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$transparentBoard=[System.Drawing.Bitmap]::new($boardWidth,$boardHeight,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bg=[System.Drawing.Graphics]::FromImage($board)
$tg=[System.Drawing.Graphics]::FromImage($transparentBoard)
$labelFont=[System.Drawing.Font]::new('Segoe UI',28,[System.Drawing.FontStyle]::Regular)
$detailFont=[System.Drawing.Font]::new('Segoe UI',18,[System.Drawing.FontStyle]::Regular)
$labelBrush=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,240,241,244))
$detailBrush=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,183,187,196))
try {
  $bg.Clear([System.Drawing.Color]::FromArgb(255,62,65,72))
  $tg.Clear([System.Drawing.Color]::Transparent)
  $bg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $tg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  for($i=0;$i -lt $partSpecs.Count;$i++) {
    $name=$partSpecs[$i].name
    $piece=[System.Drawing.Bitmap]::new((Join-Path $partsDir ($name+'.png')))
    try {
      $col=$i % 5; $row=[int][Math]::Floor($i/5)
      $cellX=$col*600; $cellY=$row*900
      $scale=[Math]::Min(510.0/$piece.Width,710.0/$piece.Height)
      $drawW=[int][Math]::Round($piece.Width*$scale); $drawH=[int][Math]::Round($piece.Height*$scale)
      $drawX=$cellX+[int]((600-$drawW)/2)
      $drawY=$cellY+40+[int]((710-$drawH)/2)
      $dest=[System.Drawing.Rectangle]::new($drawX,$drawY,$drawW,$drawH)
      $bg.DrawImage($piece,$dest)
      $tg.DrawImage($piece,$dest)
      $bg.DrawString(($name+'.png'),$labelFont,$labelBrush,[single]($cellX+32),[single]($cellY+800))
      $bg.DrawString(('Preview part '+($i+1)+' / 10'),$detailFont,$detailBrush,[single]($cellX+34),[single]($cellY+848))
    } finally {$piece.Dispose()}
  }
  $board.Save((Join-Path $previewRoot 'parts_preview_labeled.png'),[System.Drawing.Imaging.ImageFormat]::Png)
  $transparentBoard.Save((Join-Path $previewRoot 'parts_atlas_transparent.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $bg.Dispose();$tg.Dispose();$board.Dispose();$transparentBoard.Dispose()
  $labelFont.Dispose();$detailFont.Dispose();$labelBrush.Dispose();$detailBrush.Dispose()
}
$partRecords | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $previewRoot 'parts_manifest.json') -Encoding utf8
$originalRecords=Get-Content -LiteralPath (Join-Path $previewRoot 'original_hashes.json') -Raw | ConvertFrom-Json
foreach($originalRecord in $originalRecords) {
  $currentHash=(Get-FileHash -LiteralPath $originalRecord.Path -Algorithm SHA256).Hash
  if($currentHash -ne $originalRecord.Hash){throw ('Original file changed: '+$originalRecord.Path)}
}
if(@(Get-ChildItem -LiteralPath $partsDir -Filter '*.png').Count -ne 10){throw 'Expected exactly 10 cutouts.'}
$partRecords | Select-Object file,preview_canvas,original_canvas | ConvertTo-Json -Compress -Depth 4
'Original image folder verified unchanged.'

