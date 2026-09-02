#!/usr/bin/env bash

#set -x
set -e
set -o pipefail
shopt -s nullglob

cd "$(dirname "${BASH_SOURCE[0]}")/../"

SIZE=$1

if [ -z "$SIZE" ]; then
    echo "This script reduces the colorspace, resizes and recompresses all images" >&2
    echo "All new images will be written to the corresponding directory; so size=200 will create 200x200/*" >&2
    echo "Syntax: $0 <size>"
    exit 1
fi

if ! [[ "$SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: SIZE must be a number" >&2
    exit 1
fi

if (( "$SIZE" < 64 )) || (( "$SIZE" > 1024 )); then
    echo "Error: SIZE must be between 64 and 1024" >&2
    exit 1
fi


function process() {
    local img=$1
    local size=$2
    local destdir=$3

    local dest="${destdir}/$(basename ${img})"

    if [ -e "$dest" ] && [ "$dest" -nt "$img" ]
    then
        #echo "Skipping ${img}..."
        return 0
    fi

    echo "Processing ${img}"

    # basic checks
    read -r orig_width orig_height < <(
        magick -quiet "$img" -format '%[width] %[height]\n' info:
    )

    if (( orig_width != orig_height ))
    then
        echo "  - skipping: image is not square (${orig_width}x${orig_height})"
        return 1
    fi
    if (( orig_width < size ))
    then
        echo "  - skipping: image is smaller than ${size}px (${orig_width}x${orig_height})"
        return 1
    fi


    # two-step encoding process because we need to find the number of colors to make the palette as small as possible
    local tmp="${destdir}/$(basename "${img}" ".png").step1.png"

    magick -quiet \
        "$img" \
        -strip \
        -resize "${size}x${size}!" \
        -extent "${size}x${size}" \
        -background none \
        -gravity center \
        -colors 255 \
        +dither \
        "$tmp"

    local ncolors=$(magick "$tmp" -format "%[colors]" info:)

    local depth
    if   [ "$ncolors" -le 4 ]; then depth=2
    elif [ "$ncolors" -le 16 ]; then depth=4
    else depth=8
    fi

    magick "$tmp" \
        -define png:bit-depth=$depth \
        -define png:color-type=3 \
        -define png:compression-level=9 \
        -define png:compression-filter=5 \
        -define png:compression-strategy=1 \
        "$dest"

    # Check if original is smaller than target
    local tmp_size=$(stat -f%z "$tmp" 2>/dev/null || stat -c%s "$tmp" 2>/dev/null)
    local dest_size=$(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest" 2>/dev/null)
    if [ "$tmp_size" -le "$dest_size" ]; then
        #echo "  - intermediate image ${tmp} is smallest (${tmp_size} vs ${dest_size} bytes), using intermediate"
        cp "$tmp" "$dest"
    fi
    rm -f "$tmp"

    return 0
}


SUBDIR="${SIZE}x${SIZE}"
mkdir -p "$SUBDIR"

errors=0
for image in bron/*.png
do
    if ! process "$image" "$SIZE" "$SUBDIR"
    then
        errors=$((errors + 1))
    fi
done

if (( errors > 0 ))
then
    echo "Encountered ${errors} errors while processing"
    exit 1
fi

exit 0
