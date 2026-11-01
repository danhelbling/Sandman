#!/usr/bin/env python3
"""Pull candidate frames for every movie in movies.js.

Needs ffmpeg, plus yt-dlp for YouTube links.
Usage:  python3 fetch_frames.py               (all movies)
        python3 fetch_frames.py movie1        (just one)
        python3 fetch_frames.py --every 0.5   (even more frames)

Frames are grabbed every --every seconds (more often in the first --intro
seconds of each clip, where title screens usually are) plus at every scene
cut. Blurry and in-between frames are kept on purpose: they make great
hard frames. Only fully black frames are dropped.
"""
import argparse, json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)

ap = argparse.ArgumentParser()
ap.add_argument("movies", nargs="*", help="movie ids to process (default: all)")
ap.add_argument("--every", type=float, default=1, help="grab a frame every N seconds (default 1)")
ap.add_argument("--intro", type=float, default=300, help="first N seconds of each clip get extra frames (default 300)")
ap.add_argument("--intro-every", type=float, default=0.5, help="frame spacing inside the intro (default 0.5)")
ap.add_argument("--scene", type=float, default=0.2, help="scene-cut sensitivity, lower = more (default 0.2)")
ap.add_argument("--target", type=int, default=0, help="cap frames per movie, 0 = keep all (default 0)")
ap.add_argument("--min-peak", type=int, default=40,
                help="drop frames whose BRIGHTEST pixel is below this (pure black). "
                     "Title text on black is kept. (default 40)")
args = ap.parse_args()

if not shutil.which("ffmpeg"):
    sys.exit("ffmpeg is not installed. See README.md, step 1.")

# Read movies.js (strip // comments, then pull id + clips out of each block)
src = re.sub(r"(?m)^\s*//.*$|(?<=[,\[\s\"])\s*//[^\n]*", "", open("movies.js", encoding="utf-8").read())
movies = []
for m in re.finditer(r'id:\s*"([^"]+)".*?clips:\s*\[(.*?)\]', src, re.S):
    movies.append((m.group(1), re.findall(r'"([^"]+)"', m.group(2))))
if not movies:
    sys.exit("No movies found in movies.js")

failed = []
for mid, clips in movies:
    if args.movies and mid not in args.movies:
        continue
    vdir, fdir = os.path.join("videos", mid), os.path.join("frames", mid)
    os.makedirs(vdir, exist_ok=True)
    shutil.rmtree(fdir, ignore_errors=True)
    os.makedirs(fdir)
    for n, clip in enumerate(clips, 1):
        if clip.startswith("http"):
            vid = os.path.join(vdir, f"clip{n}.mp4")
            if not os.path.exists(vid):
                if not shutil.which("yt-dlp"):
                    sys.exit("yt-dlp is not installed. See README.md, step 1.")
                print(f">> Downloading {mid} clip {n}: {clip}")
                r = subprocess.run(["yt-dlp", "-q", "--no-playlist",
                                    "-f", "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720]/b",
                                    "--merge-output-format", "mp4", "-o", vid, clip],
                                   stdin=subprocess.DEVNULL)
                if r.returncode != 0 or not os.path.exists(vid):
                    print(f"!! Skipping {mid} clip {n}: download failed (video removed or private?)")
                    failed.append(f"{mid} clip {n}"); continue
        else:
            vid = clip
            if not os.path.exists(vid):
                print(f"!! Skipping {mid} clip {n}: file not found: {vid}")
                failed.append(f"{mid} clip {n}"); continue
        print(f">> Pulling frames from {mid} clip {n}")
        gap = f"if(lt(t\\,{args.intro})\\,{args.intro_every}\\,{args.every})"
        vf = (f"select='gt(scene\\,{args.scene})+isnan(prev_selected_t)+gte(t-prev_selected_t\\,{gap})',"
              f"signalstats,metadata=mode=select:key=lavfi.signalstats.YMAX:value={args.min_peak}:function=greater,"
              "scale=1280:-2")
        r = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-i", vid, "-vf", vf,
                            "-fps_mode", "vfr", "-q:v", "3", os.path.join(fdir, f"c{n}_%04d.jpg")])
        if r.returncode != 0:
            print(f"!! Could not pull frames from {vid}"); failed.append(f"{mid} clip {n}")

    # Optional cap: thin down to --target frames, spread evenly across all clips
    files = sorted(f for f in os.listdir(fdir) if f.endswith(".jpg"))
    if args.target and len(files) > args.target:
        keep = {files[round(i * (len(files) - 1) / (args.target - 1))] for i in range(args.target)}
        for f in files:
            if f not in keep: os.remove(os.path.join(fdir, f))

# manifest.js lists every frame so index.html can show them (works without a web server)
out = {}
if os.path.isdir("frames"):
    for mid in sorted(os.listdir("frames")):
        d = os.path.join("frames", mid)
        if os.path.isdir(d):
            out[mid] = sorted(f"frames/{mid}/{f}" for f in os.listdir(d) if f.endswith(".jpg"))
open("manifest.js", "w", encoding="utf-8").write("window.FRAME_MANIFEST = " + json.dumps(out, indent=1) + ";\n")
print("\nFrames per movie:", {k: len(v) for k, v in out.items()})
if failed:
    print("These clips failed:", ", ".join(failed))
print("Done. Open index.html, click Pick Frames, and choose 5 per movie.")
