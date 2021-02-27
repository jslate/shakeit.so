function random_item(items) {
  return items[Math.floor(Math.random()*items.length)];
}

setInterval(() => {
  const artist = document.getElementById("artist");
  const song = document.getElementById("song");
  const image = document.getElementById("image");
  const progress_bar = document.getElementById("progress_bar");
  const time_remaining = document.getElementById("time_remaining");
  const note = document.getElementById("note");
  fetch('/np')
    .then(response => response.json())
    .then(data => {
      console.log("update!", data)
      artist.innerHTML = data.artist;
      song.innerHTML = data.song;
      time_remaining.innerHTML = data.time_remaining;
      progress_bar.style = `width: ${data.progress_width}`;
      song.innerHTML = data.song;
      image.src = data.image;
      note.innerHTML = random_item(data.notes);
    });
}, 5000);
