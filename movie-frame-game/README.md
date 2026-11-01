# Name That Movie

A small local website for a frame-guessing game. Each movie shows 5 frames, from very hard to the title screen.

## 1. Get the frames (on your computer)
You need `yt-dlp`, `ffmpeg` and Python 3. On a Mac: `brew install yt-dlp ffmpeg python`

```
cd movie-frame-game
python3 fetch_frames.py
```
To redo one movie, run `python3 fetch_frames.py ash`.
You get a frame every second (every half second in the first 5 minutes of each clip, for title screens), plus one at every scene cut. Blurry and in-between frames are kept, and only fully black frames are dropped.
For even more frames, use `--every 0.5`. For fewer, use `--every 3`.

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
Add an entry to `movies.js` with an `id`, `title`, and a list of YouTube `clips`, then run `python3 fetch_frames.py <id>`. Video files on your computer work in `clips` too.
