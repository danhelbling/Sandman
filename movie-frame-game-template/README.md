# Name That Movie: build your own

A guessing game for movie night. Each movie shows 5 frames, from almost impossible (frame 1) to the title screen (frame 5).
You pick the movies, pull frames from YouTube clips or your own video files, choose the 5 frames for each movie, and play it full-screen.

Everything runs on your own computer. Nothing gets uploaded.

---

## Step 1: Install the tools (one time)

You need **Python 3**, **ffmpeg**, and **yt-dlp** (yt-dlp is only needed for YouTube links).

**Mac:** open Terminal and run these two lines:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python ffmpeg yt-dlp
```
(Skip the first line if you already have Homebrew.)

**Windows:** open PowerShell and run:
```
winget install Python.Python.3.12 Gyan.FFmpeg yt-dlp.yt-dlp
```
Then close PowerShell and open it again.

## Step 2: Add your movies

Open `movies.js` in any text editor (TextEdit, Notepad, VS Code). For each movie, set:
- `id`: a short name with no spaces, like `"shrek2"`.
- `title`: the answer shown when you click **Reveal**.
- `clips`: YouTube links or video file paths. Use a few different scenes per movie for more variety, and include one clip with the **title screen**.

Tip: search YouTube for "<movie> opening scene" and "<movie> title sequence".

## Step 3: Pull the frames

In Terminal or PowerShell, go into this folder and run the script:
```
cd path/to/this/folder
python3 fetch_frames.py
```
(On Windows, use `python` if `python3` doesn't work.)

You get up to 200 frames per movie. It skips black frames and spreads the 200 across every clip.
- For fewer frames: `python3 fetch_frames.py --target 50`
- To redo one movie: `python3 fetch_frames.py shrek2`
- If a clip says "download failed", that YouTube video was removed. Swap the link in `movies.js` and run again.

## Step 4: Pick your 5 frames

Open `index.html` in Chrome, Safari, or Edge. It starts in **Pick Frames**.
1. Click a movie tab.
2. Under any frame, click **1–5** to put it in that spot (1 = hardest, 5 = title screen). Click the same number again to remove it.
3. Click a frame to see it big. Use **← / →** to browse and the keys **1–5** to assign.
4. To make a frame harder, click **Zoom** on a slot at the top, then click the slot image where you want to zoom in.

Your picks are saved in that browser. To keep them for good, or to move the game to another computer, click **Export picks.js** and replace the `picks.js` in this folder with the downloaded file.

## Step 5: Play

Click **Play**. Hook a laptop up to a TV and press **F** for full screen.

| Key | Does |
|---|---|
| → / ← | next or previous frame |
| ↓ / ↑ | next or previous movie |
| Space or R | reveal or hide the title |
| F | full screen |

**Scoring idea:** guess on frame 1 = 5 points, frame 2 = 4, and so on down to 1 point on the title screen.

---

### What's in this folder
| File | What it is |
|---|---|
| `index.html` | the game and the frame picker |
| `movies.js` | **your movie list (edit this)** |
| `fetch_frames.py` | downloads clips and pulls frames |
| `manifest.js` | list of pulled frames (made by the script) |
| `picks.js` | your saved picks (replace it with your export) |
| `frames/`, `videos/` | made by the script |

Screenshots from movies are copyrighted. Keep the game for personal use and don't post the frames publicly.
