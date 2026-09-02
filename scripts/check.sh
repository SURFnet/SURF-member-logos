#!/usr/bin/env bash

#set -x
set -e
set -o pipefail
shopt -s nullglob

cd "$(dirname "${BASH_SOURCE[0]}")/../"

if ! which magick > /dev/null
then
    echo "FATAL: Imagemagick's 'magick' command not found"
    exit 2
fi

# minimal size of image
MIN_SIZE=200

function check() {
    local img=$1

    echo -n "Checking ${img} ... "

    # basic checks
    read -r width height type< <(
        magick -quiet "$img" -format '%[width] %[height] %[magick]\n' info:
    )

    if [[ "$type" != "PNG" ]]
    then
        echo "❌"
        echo "  - ERROR: image is not a PNG (found '$type')"
        return 1
    fi
    if (( width != height ))
    then
        echo "❌"
        echo "  - ERROR: image is not square (${width}x${height})"
        return 1
    fi
    if (( width < MIN_SIZE ))
    then
        echo "❌"
        echo "  - skipping: image is smaller than ${MIN_SIZE}px (${width}x${height})"
        return 1
    fi

    echo "✅ (${width}x${height})"

    return 0
}


echo "Start logo check"

errors=0
for image in bron/*.png
do
    if ! check "$image"
    then
        errors=$((errors + 1))
    fi
done

if (( errors > 0 ))
then
    echo "Encountered ${errors} errors while processing"
    exit 1
fi

echo "Done checking logos"
echo

exit 0
