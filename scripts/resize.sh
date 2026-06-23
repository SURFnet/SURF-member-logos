#!/usr/bin/env bash

#set -x
set -e
set -o pipefail
shopt -s nullglob

cd "$(dirname "${BASH_SOURCE[0]}")/../"

SIZE=$1

if [ -z "$SIZE" ]; then
    echo "This script reduces the colorspace, resizes and recompresses all images" >&2
    echo "All new images will be written to the corrsponding directory; so size=200 will create 200x200/" >&2
    echo "Syntax: $0 <size>"
    exit 1
fi

if ! [[ "$SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: SIZE must be a number" >&2
    exit 1
fi

if [ "$SIZE" -lt 64 ] || [ "$SIZE" -gt 1024 ]; then
    echo "Error: SIZE must be between 64 and 1024" >&2
    exit 1
fi


function process() {
    img=$1
    destdir=$2

    echo "Processing ${img}..."

    # two-step encoding process because we need to find the number of colors to make the palette as small as possible
    tmp="${destdir}/$(basename "${img}" ".png").step1.png"
    dest="${destdir}/${img}"

    magick "$img" \
        -resize "${SIZE}x${SIZE}!" \
        -extent "${SIZE}x${SIZE}" \
        -background none \
        -gravity center \
        -colors 255 \
        +dither \
        "$tmp"

    ncolors=$(magick "$tmp" -format "%k" info:)

    if   [ "$ncolors" -le 4 ]; then depth=2
    elif [ "$ncolors" -le 16 ]; then depth=4
    else depth=8
    fi

    magick "$tmp" \
        -strip \
        -define png:bit-depth=$depth \
        -define png:color-type=3 \
        -define png:compression-level=9 \
        -define png:compression-filter=5 \
        -define png:compression-strategy=1 \
        "$dest"

    # Check if original is smaller than target
    tmp_size=$(stat -f%z "$tmp" 2>/dev/null || stat -c%s "$tmp" 2>/dev/null)
    dest_size=$(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest" 2>/dev/null)
    if [ "$tmp_size" -le "$dest_size" ]; then
        echo "Tmp ${tmp} is smallest (${tmp_size} bytes), using tmp"
        cp "$tmp" "$dest"
    fi
    rm -f "$tmp"

}


SUBDIR="${SIZE}x${SIZE}"
rm -rf "$SUBDIR"
mkdir -p "$SUBDIR"

for image in *.png
do
    process "$image" "$SUBDIR"
done

exit 0
