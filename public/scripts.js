function random_item(items) {
  return items[Math.floor(Math.random()*items.length)];
}

const getLocalTime = (date) => {
  const currentTimeZoneOffset = date.getTimezoneOffset() * 60_000;
  return new Date(date - currentTimeZoneOffset)
}

const countdown = (date, element) => {
  const setCountdownValue = () => {
    const totalSeconds = Math.floor((date.valueOf() - new Date().valueOf()) / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    const totalDays = Math.floor(totalHours / 24)
    const hours = totalHours % 24;
    const minutes = totalMinutes % 60;
    const seconds = totalSeconds % 60;

    console.log("totalMinutes", totalMinutes);

    if (totalMinutes < 30) {
      element.style = ("display: none;");
      document.getElementById("zoom-link").style = "display: block;"
    } else {
      element.innerHTML = `Zoom link to appear in: ${totalDays}d ${hours}h ${minutes}m ${seconds}s`;
    }
  }

  setCountdownValue(date, element)
  setInterval(() => setCountdownValue(date, element), 1000)
}

window.addEventListener('DOMContentLoaded', (event) => {
  const date = getLocalTime(new Date('2021-04-03T18:30:00.000000'));
  countdown(date, document.getElementById("countdown"));
});

const width = (data) => {
  return `${Math.floor(data.progress / data.duration * 100)}%`;
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
      progress_bar.style = `width: ${width(data)}`;
      song.innerHTML = data.song;
      image.src = data.image;
      note.innerHTML = random_item(data.notes);
    });
}, 5000);
