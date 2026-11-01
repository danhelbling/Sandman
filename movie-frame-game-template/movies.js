// YOUR MOVIES GO HERE. The order below is Movie 1, Movie 2, Movie 3, ...
//
// For each movie:
//   id    - a short name with no spaces (used for the folder name)
//   title - what shows when you click Reveal
//   clips - one or more YouTube links, OR video files on your computer.
//           Frames are pulled from every clip, so using a few different
//           scenes gives you more variety to pick from.
//
// Copy a block to add another movie. Keep the commas between blocks.
window.MOVIES = [
  {
    id: "movie1",
    title: "Example Movie One (2001)",
    clips: [
      "https://www.youtube.com/watch?v=XXXXXXXXXXX",
      "https://youtu.be/YYYYYYYYYYY"
    ]
  },
  {
    id: "movie2",
    title: "Example Movie Two (2010)",
    clips: [
      "my-videos/movie-two.mp4"   // a video file, path relative to this folder
    ]
  }
];
