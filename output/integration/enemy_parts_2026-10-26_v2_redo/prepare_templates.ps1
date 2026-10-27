$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='D:\Godot Project\soujourn--echoes-of-the-soul'
$redo=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v2_redo'
$old=Join-Path $root 'output\integration\enemy_parts_2026-10-26_v1\originals'
$templates=Join-Path $redo 'templates'
New-Item -ItemType Directory -Path $templates -Force|Out-Null
$names=@('body.png','head.png','lef leg.png','left hand.png','left palm.png','right bicep.png','right hand.png','right leg.png','right palm.png','tail.png')
$manifest=@()
foreach($name in $names){
 $src=[Drawing.Bitmap]::new((Join-Path $old $name))
 $scale=[int][Math]::Floor(768.0/[Math]::Max($src.Width,$src.Height))
 $w=$src.Width*$scale;$h=$src.Height*$scale
 $x=[int][Math]::Floor((1024-$w)/2);$y=[int][Math]::Floor((1024-$h)/2)
 $dest=[Drawing.Bitmap]::new(1024,1024,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($dest)
 $attrs=[Drawing.Imaging.ImageAttributes]::new()
 try{
  $g.Clear([Drawing.Color]::Transparent)
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
  $cm=[Drawing.Imaging.ColorMatrix]::new()
  $cm.Matrix00=0;$cm.Matrix11=0;$cm.Matrix22=0
  $cm.Matrix40=0.48;$cm.Matrix41=0.51;$cm.Matrix42=0.55
  $attrs.SetColorMatrix($cm)
  $g.DrawImage($src,[Drawing.Rectangle]::new($x,$y,$w,$h),0,0,$src.Width,$src.Height,[Drawing.GraphicsUnit]::Pixel,$attrs)
  $dest.Save((Join-Path $templates $name),[Drawing.Imaging.ImageFormat]::Png)
  $manifest+=[pscustomobject]@{file=$name;width=$src.Width;height=$src.Height;scale=$scale;crop_x=$x;crop_y=$y;crop_width=$w;crop_height=$h;template_width=1024;template_height=1024}
 }finally{$src.Dispose();$dest.Dispose();$g.Dispose();$attrs.Dispose()}
}
$manifest|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $redo 'template_manifest.json') -Encoding utf8
'Created 10 fixed-frame geometry templates; no game changes.'
