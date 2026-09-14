#!/bin/bash
# Regenerates the wallpapers: ./make-backgrounds.sh [width] [height]
# Keep the RED/BRED/BG values below in sync with colors.toml.
set -e
W=${1:-2560}; H=${2:-1440}
RED='#C4143F'; BRED='#D70A53'; BG='#0A0A0A'
cd "$(dirname "$0")/backgrounds"

# 01 diagonal slash
magick -size 160x160 xc:"$BG" -stroke '#1f1f1f' -strokewidth 2 \
  -draw "line 0,160 160,0" -draw "line -80,80 80,-80" -draw "line 80,240 240,80" _t.png
magick -size ${W}x${H} tile:_t.png -fill none \
  -stroke "$BRED" -strokewidth 7 -draw "line $((W*27/100)),$H $((W*82/100)),0" \
  -stroke '#cfcfcf' -strokewidth 1 -draw "line $((W*24/100)),$H $((W*79/100)),0" \
  -stroke '#cfcfcf' -strokewidth 1 -draw "line $((W*30/100)),$H $((W*84/100)),0" 01-slash.png

# 02 perspective grid with a red horizon line
d=""; for ((x=-W; x<=2*W; x+=160)); do d+="line $x,0 $x,560 "; done
for ((y=0; y<=560; y+=56)); do d+="line 0,$y $W,$y "; done
magick -size ${W}x560 xc:black -stroke white -strokewidth 3 -fill none -draw "$d" _g.png
magick _g.png -alpha set -virtual-pixel transparent \
  -distort Perspective "0,0 $((W*44/100)),0  $W,0 $((W*56/100)),0  0,560 $((-W*43/100)),560  $W,560 $((W*143/100)),560" _gp.png
magick -size ${W}x560 gradient:black-'#707070' _gm.png
magick _gp.png _gm.png -alpha off -compose CopyOpacity -composite _gpm.png
magick -size ${W}x${H} xc:"$BG" _gpm.png -geometry +0+$((H-560)) -composite \
  -stroke "$BRED" -strokewidth 2 -draw "line 0,$((H-560)) $W,$((H-560))" 02-horizon.png

# 03 concentric rings, one of them red
cx=$((W/2)); cy=$((H/2)); d=""
for ((r=60; r<=1500; r+=46)); do d+="circle $cx,$cy $((cx+r)),$cy "; done
magick -size ${W}x${H} xc:"$BG" -stroke '#e8e8e8' -strokewidth 2 -fill none -draw "$d" \
  -stroke "$RED" -strokewidth 6 -draw "circle $cx,$cy $((cx+520)),$cy" \
  \( -size ${W}x${H} radial-gradient:white-black -evaluate multiply 1.1 \) \
  -compose multiply -composite 03-rings.png

# 04 topographic contours, white on the left turning red on the right
magick -size ${W}x${H} plasma:fractal -colorspace Gray -blur 0x16 -normalize \
  -posterize 18 -edge 2 -threshold 12% _lines.png
magick -size ${W}x${H} radial-gradient:white-black -roll +620+300 -evaluate pow 1.5 _mask.png
magick -size ${W}x${H} xc:'#9E9E9E' \( -size ${W}x${H} xc:'#E01050' \) _mask.png -composite _color.png
magick -size ${W}x${H} xc:"$BG" _color.png _lines.png -composite 04-contour.png

# 05 eclipse: two nested rings with a soft bloom
magick -size ${W}x${H} xc:"$BG" \
  -fill none -stroke "$RED" -strokewidth 6 -draw "circle $cx,$((cy+40)) $cx,$((cy-520))" \
  -stroke '#e0e0e0' -strokewidth 1 -draw "circle $cx,$((cy+40)) $cx,$((cy-600))" \
  \( +clone -blur 0x70 -evaluate multiply 0.8 \) -compose screen -composite 05-eclipse.png

# 06 halftone dot field, red bleeding in from the right
magick -size ${W}x${H} radial-gradient:white-black -roll +780+420 -evaluate pow 3.4 \
  -ordered-dither h8x8a -fill "$RED" -opaque white -background "$BG" -alpha remove 06-halftone.png

# 07 flat black
magick -size ${W}x${H} xc:"$BG" 07-void.png

rm -f _*.png

# README thumbnails
mkdir -p ../docs
for f in 0*.png; do magick "$f" -resize 480x270 -depth 8 -strip "../docs/$f"; done

echo "done: $(ls 0*.png | tr '\n' ' ')"
