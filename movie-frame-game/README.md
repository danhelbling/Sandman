# Name That Movie

A small local website for a frame-guessing game. Each movie shows 5 frames, from very hard to the title screen.

## 1. Get the frames (one time, on your computer)
You need `yt-dlp` and `ffmpeg` (Mac: `brew install yt-dlp ffmpeg`).

```bash
cd movie-frame-game
./fetch_frames.sh            # all movies
./fetch_frames.sh ash        # or just one
```
This downloads the YouTube clips listed in `movies.js` into `videos/` and saves one frame per scene change into `frames/<movie>/`.
You get about 50 candidate frames per movie, with black frames skipped. For more, run `TARGET=100 ./fetch_frames.sh`.

## 2. Pick the 5 frames
Open `index.html` and click **Pick Frames**. Pick a movie tab. Under any of the ~50 frames, click **1–5** to put it in that position (1 = hardest, 5 = title screen). Click a frame to view it large; there, ←/→ browse and keys 1–5 assign. Clicking a position again removes it. To make a frame harder, click **Zoom** on the slot (up to 4x), then click the slot image where you want to zoom in.
Your picks save in that browser. Click **Export picks.js** and replace `picks.js` in this folder to keep them for good.

## 3. Play
Click **Play**.
- `→` / `←`: next or previous frame
- `↓` / `↑`: next or previous movie (or the Movie 1–4 tabs)
- `Space` / `R`: reveal the title
- `F`: fullscreen

## Adding a movie
Add an entry to `movies.js` with an `id`, `title`, and a list of YouTube `clips`, then run `./fetch_frames.sh <id>`.
