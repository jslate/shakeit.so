const formatTime = (milliseconds) => {
  const totalSeconds = milliseconds / 1000;
  const minutes = Math.floor(totalSeconds / 60);
  let seconds = Math.floor(totalSeconds % 60);
  if (seconds < 10) { seconds = `0${seconds}`; }

  return `${minutes}:${seconds}`;
}

const getLocalTime = (date) => {
  const currentTimeZoneOffset = date.getTimezoneOffset() * 60_000;
  return new Date(date - currentTimeZoneOffset)
}

const countdown = (date) => {
  const counter = document.getElementById("counter")
  const zoomLink = document.getElementById("zoom-link");
  if (!zoomLink) { return; }
  const setCountdownValue = () => {
    const totalSeconds = Math.floor((date.valueOf() - new Date().valueOf()) / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    const totalDays = Math.floor(totalHours / 24)
    const hours = totalHours % 24;
    const minutes = totalMinutes % 60;
    const seconds = totalSeconds % 60;

    if (totalMinutes < 0) {
      counter.style = "display: none;";
      zoomLink.style = "display: block;"
    } else {
      counter.style = "display: block;";
      zoomLink.style = "display: none;"
      counter.innerHTML = `${totalDays}d ${hours}h ${minutes}m ${seconds}s`;
    }
  }

  setCountdownValue(date, counter)
  setInterval(() => setCountdownValue(date, counter), 1000)
}

const width = (progress, duration) => {
  return `${Math.floor(progress / duration * 100)}%`;
}

const player = () => {
  const artist = document.querySelector(".now-playing .artist");
  if (!artist) { return; }
  const song = document.querySelector(".now-playing .song");
  const image = document.querySelector(".now-playing .image");
  const progress_bar = document.querySelector(".progress-container .progress-bar");
  const time_remaining = document.querySelector(".progress-container .time-remaining");
  const noteElement = document.querySelector(".now-playing .note");

  let iteration = 0;
  setInterval(() => {
    iteration += 1;
    if (iteration % 5 === 0) {
      fetch(`/np?junk=${Math.random()}`)
        .then(response => response.json())
        .then(data => {
          if (!!data && !!data.title) {
            artist.innerHTML = data.artist;
            song.innerHTML = data.song;
            time_remaining.innerHTML = data.time_remaining;
            progress_bar.style = `width: ${width(data.progress, data.duration)}`;
            progress_bar.dataset.progress = data.progress;
            progress_bar.dataset.duration = data.duration;
            song.innerHTML = data.title;
            image.src = data.image;
            let note = data.notes[iteration / 5 % data.notes.length];

            if (note && note.match(/^\d{4}$/)) {
              const position = Math.floor(parseInt(data.progress) / parseInt(data.duration) * 5);
              noteElement.innerHTML = note.slice(0, position) + "????".slice(position);
            } else if (note && note.match(/.+;.+/)) {
              const position = Math.floor(parseInt(data.progress) / parseInt(data.duration) * 2);
              noteElement.innerHTML = `<span style="color: lightblue">${note.split(";")[position]}</span>`
            } else if (!!note) {
              noteElement.innerHTML = note;
            } else {
              noteElement.innerHTML = "";
            }
          }
        });
      } else {
        const data = progress_bar.dataset;
        if (data.duration && data.progress) {
          const duration = parseInt(data.duration);
          const newProgress = parseInt(data.progress) + 1000;
          if (newProgress <= duration) {
            progress_bar.style = `width: ${width(newProgress, duration)}`;
            progress_bar.dataset.progress = newProgress;
            time_remaining.innerHTML = formatTime(duration - newProgress);
          }
        }

      }
  }, 1000);
}

window.addEventListener('DOMContentLoaded', (event) => {
  const date = getLocalTime(new Date('2021-05-08T17:30:00.000000'));
  countdown(date);
  player();
});
