#!/usr/bin/env bash
# Downloads each movie's clips and pulls one candidate frame per scene change.
# Needs: yt-dlp, ffmpeg, python3.   Usage: ./fetch_frames.sh  [movie_id ...]
set -euo pipefail
cd "$(dirname "$0")"
command -v yt-dlp >/dev/null || { echo "Install yt-dlp first (brew install yt-dlp  or  pip install yt-dlp)"; exit 1; }
command -v ffmpeg >/dev/null || { echo "Install ffmpeg first (brew install ffmpeg)"; exit 1; }

TARGET="${TARGET:-50}"         # candidate frames kept per movie
SCENE="${SCENE:-0.25}"         # scene-change sensitivity (lower = more cuts detected)
EVERY="${EVERY:-6}"            # also grab a frame at least every N seconds
MIN_BRIGHT="${MIN_BRIGHT:-28}" # drop frames darker than this (0-255 average)

# Read "id url" pairs out of movies.js
pairs=$(python3 - <<'PY'
import re
src = open("movies.js").read()
for block in re.finditer(r'id:\s*"([^"]+)".*?clips:\s*\[(.*?)\]', src, re.S):
    for n, url in enumerate(re.findall(r'"(https?://[^"]+)"', block.group(2)), 1):
        print(block.group(1), n, url)
PY
)

only=" $* "
failed=""
while read -r id n url; do
  [ -z "$id" ] && continue
  if [ "$only" != "  " ] && [[ "$only" != *" $id "* ]]; then continue; fi
  vdir="videos/$id"; fdir="frames/$id"; mkdir -p "$vdir" "$fdir"
  vid="$vdir/clip$n.mp4"
  if [ ! -s "$vid" ]; then
    echo ">> Downloading $id clip $n: $url"
    if ! yt-dlp -q --no-playlist -f "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720]/b" \
      --merge-output-format mp4 -o "$vid" "$url" </dev/null; then
      echo "!! Skipping $id clip $n (download failed). Replace this link in movies.js." >&2
      failed="$failed $id#$n"; rm -f "$vid"; continue
    fi
  fi
  echo ">> Extracting scene frames from $vid"
  rm -f "$fdir"/c${n}_*.jpg
  # a frame at every scene change, plus one every $EVERY s; black/dark frames dropped
  ffmpeg -nostdin -loglevel error -i "$vid" \
    -vf "select='gt(scene\,$SCENE)+gte(t-prev_selected_t\,$EVERY)',signalstats,metadata=mode=select:key=lavfi.signalstats.YAVG:value=$MIN_BRIGHT:function=greater,scale=1280:-2" \
    -fps_mode vfr -q:v 3 "$fdir/c${n}_%04d.jpg" \
    || { echo "!! Could not extract frames from $vid" >&2; failed="$failed $id#$n"; }
done <<< "$pairs"

# Write manifest.js listing every candidate frame (works when opened as a file://)
TARGET="$TARGET" python3 - <<'PY'
import os, json
target = int(os.environ["TARGET"])
# Thin each movie down to ~TARGET frames, evenly spread across all its clips
for mid in sorted(os.listdir("frames")) if os.path.isdir("frames") else []:
    d = os.path.join("frames", mid)
    files = sorted(f for f in os.listdir(d) if f.endswith(".jpg"))
    if len(files) > target:
        keep = {files[round(i * (len(files) - 1) / (target - 1))] for i in range(target)}
        for f in files:
            if f not in keep: os.remove(os.path.join(d, f))
out = {}
for mid in sorted(os.listdir("frames")) if os.path.isdir("frames") else []:
    d = os.path.join("frames", mid)
    out[mid] = sorted(f"frames/{mid}/{f}" for f in os.listdir(d) if f.endswith(".jpg"))
open("manifest.js", "w").write("window.FRAME_MANIFEST = " + json.dumps(out, indent=1) + ";\n")
print("manifest.js written:", {k: len(v) for k, v in out.items()})
PY
[ -n "$failed" ] && echo "Clips that failed:$failed"
echo "Done. Open index.html, click Setup, and pick 5 frames per movie."
