#!/bin/bash
# render.sh [output.png] [width] [height] [path]
# Examples:
#   ./render.sh                                    # main view
#   ./render.sh /tmp/x.png 1600 1000 /i/?get=a
set -e
OUT="${1:-/tmp/paperwhite.png}"
W="${2:-1600}"
H="${3:-1000}"
PATH_="${4:-/i/}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

"$CHROME" \
  --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
  --window-size="${W},${H}" \
  --screenshot="$OUT" \
  "http://localhost:8888${PATH_}"

echo "$OUT"
