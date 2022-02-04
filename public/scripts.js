


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
  if (!counter) { return; }
  const setCountdownValue = () => {
    const totalSeconds = Math.floor((date.valueOf() - new Date().valueOf()) / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    const totalDays = Math.floor(totalHours / 24)
    const hours = totalHours % 24;
    const minutes = totalMinutes % 60;
    const seconds = totalSeconds % 60;

    counter.innerHTML = totalMinutes > 0 ? `${totalDays}d ${hours}h ${minutes}m ${seconds}s` : "&nbsp;"

    if (totalMinutes < 30 && totalMinutes > 0) {
      counter.style = "display: block;";
      if (zoomLink) { zoomLink.style = "display: block;"; }
    } else if (totalMinutes < 0 && zoomLink) {
      counter.style = "display: none;";
      if (zoomLink) { zoomLink.style = "display: block;"; }
    } else {
      counter.style = "display: block;";
      if (zoomLink) { zoomLink.style = "display: none;"; }
    }
  }

  setCountdownValue(date, counter)
  setInterval(() => setCountdownValue(date, counter), 1000)
}

const width = (progress, duration) => {
  return `${Math.floor(progress / duration * 100)}%`;
}

const replacementImages = {
  "https://i.scdn.co/image/ab67616d00001e02d4a6817b14d3dea6f23c680c": "https://images-na.ssl-images-amazon.com/images/I/61J9Y0GYD7L.jpg",
  "https://i.scdn.co/image/ab67616d00001e02122fc2d4a47502e72763a092": "http://cps-static.rovicorp.com/3/JPG_500/MI0002/503/MI0002503085.jpg",
}

const player = () => {
  const artist = document.querySelector(".now-playing .artist");
  if (!artist) { return; }
  const song = document.querySelector(".now-playing .song");
  const image = document.querySelector(".now-playing .image");
  const progress_bar = document.querySelector(".progress-container .progress-bar");
  const time_remaining = document.querySelector(".progress-container .time-remaining");
  const noteElement = document.querySelector(".now-playing-container .note");
  const nowPlaying = document.querySelector(".now-playing");
  const progressConainer = document.querySelector(".progress-container");

  let iteration = 0;
  let showNote = false;
  let noteIndex = 0;
  const noteIterations = 20;


  const handleNotes = (notes, progress, duration) => {

    const updateNote = () => {
      if (notes && notes[noteIndex] && showNote) {

        const fullNote = notes[noteIndex];
        let note = fullNote;

        if (note.match(/.+;.+/)) {
          const position = Math.floor(parseInt(progress) / parseInt(duration) * 2);
          note = `<span style="color: lightblue">${note.split(";")[position]}</span>`;
        }

        if (note.match(/^https?:\/\/.*/)) {
          note = `<img src="${note}">`
        }

        noteElement.innerHTML = note;
        nowPlaying.style.display = "none";
        progressConainer.style.display = "none";
        noteElement.style.display = "flex";
      } else {
        noteElement.style.display = "none";
        nowPlaying.style.display = "grid";
        progressConainer.style.display = "block";
      }
    };

    if (!showNote && iteration % noteIterations > (noteIterations / 2)) {
      showNote = true;
      noteIndex = noteIndex >= notes.length - 1 ? 0 : noteIndex + 1;
    } else if (showNote && iteration % noteIterations <= (noteIterations / 2)) {
      showNote =  false;
    }
    updateNote()
  }

  let notes = [];
  let progress = 0;
  let duration = 0;
  setInterval(() => {
    iteration += 1;
    handleNotes(notes, progress, duration)

    if (iteration % 5 === 0) {
      fetch(`/np?junk=${Math.random()}`)
        .then(response => response.json())
        .then(data => {
          if (!!data && !!data.title) {
            artist.innerHTML = `Artist: ${data.artist}`;
            song.innerHTML = data.song;
            time_remaining.innerHTML = data.time_remaining;
            progress_bar.style = `width: ${width(data.progress, data.duration)}`;
            progress_bar.dataset.progress = data.progress;
            progress_bar.dataset.duration = data.duration;
            song.innerHTML = data.title;
            image.src = replacementImages[data.image] || data.image;
            notes = data.notes;
          }
        });
      } else {
        const data = progress_bar.dataset;
        if (data.duration && data.progress) {
          duration = parseInt(data.duration);
          const newProgress = parseInt(data.progress) + 1000;
          progress = newProgress;
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
  const date = getLocalTime(new Date('2021-08-08T00:00:00.000000'));
  // const date = getLocalTime(new Date('2021-05-08T17:00:00.000000'));
  countdown(date);
  player();


  const scriptForm = document.getElementById("script-form");
  if (scriptForm) {

    const updateScript = () => {
      const formData = new FormData(scriptForm);
      const name = formData.get("name") || "(name)";
      const organization = formData.get("organization");
      const position = formData.get("position");
      const session = formData.get("session");

      const text = [`Hi, I am ${name}.`];
      if (organization && position) {
        text.push(`I'm a ${position} with ${organization} and`);
      }

      text.push("I am super excited to join the dance party on October thirtieth " +
        "to raise money for an amazing organization. Helping Hands Grateful Hearts " +
        "works with the most vulnerable communities in South and Central America to meet " +
        "basic needs including housing, food, and clean water.");
      if (session == "both") {
        text.push("I will be attending both sessions.");
      } else if (session == "afternoon") {
        text.push("I will be attending the afternoon session.");
      } else {
        text.push("I will be attending the evening session.");
      }

      text.push("I would love to see you there. Go to shakeit dot so to sign up.")
      document.getElementById("english-script").innerHTML = text.join(" ");

      const spanishText = [`Hola, me llamo ${name}.`];
      if (organization && position) {
        spanishText.push(`Soy ${position} en ${organization} y`);
      }

      spanishText.push("Estoy muy emocionado por sumarme a la fiesta de baile el treinta de octubre y recaudar fondos para una organización increíble. Helping Hands Grateful Hearts trabaja con comunidades vulnerables en Sur y Centroamérica, brindando respuesta a necesidades básicas como vivienda, alimentos y agua.");
      if (session == "both") {
        spanishText.push("Estaré participando en las dos sesiones.");
      } else if (session == "afternoon") {
        spanishText.push("Estaré participando en la sesión de la tarde.");
      } else {
        spanishText.push("Estaré participando en la sesión de la noche.");
      }

      spanishText.push("Me encantaría verte ahí. Regístrate en shakeit punto so.")
      document.getElementById("spanish-script").innerHTML = spanishText.join(" ");
    };

    updateScript();
    scriptForm.addEventListener("keyup", updateScript);
    scriptForm.addEventListener("click", updateScript);
  }


  const songGrid = document.getElementById("song-grid");
  const songGridForm = songGrid.querySelector("form");
  if (songGrid && songGridForm) {
    songGrid.addEventListener("click", (event) => {
      const xPos = event.clientX / document.body.clientWidth;
      const yPos = event.clientY / document.body.clientHeight;
      const xPosField = songGridForm.querySelector("[name=x_pos]")
      const yPosField = songGridForm.querySelector("[name=y_pos]")
      xPosField.value = xPos;
      yPosField.value = yPos;
      songGridForm.submit();
    })
  }
});
