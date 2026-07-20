import {loadGodot} from './godot-embed.js';

const fullscreenDemoGame = () => {
  const canvas = document.querySelector("canvas.godot-canvas");

  if (canvas.requestFullscreen) {
    canvas.requestFullscreen({navigationUI: "hide"});
  } else if (canvas.webkitRequestFullscreen) { // Safari
    canvas.webkitRequestFullscreen();
  } else if (canvas.msRequestFullscreen) { // old Edge
    canvas.msRequestFullscreen();
  }
};
const demoButton = document.querySelector('.demo-button');
const loadDemoGame = async () => {
  const webSplashInner = document.querySelector(".web-splash-inner");
  const fsDiv = document.createElement("div");
  const fsBtn = document.createElement("button");

  fsDiv.classList.add("demo-fs-div");
  fsBtn.classList.add("demo-fs-btn");
  fsBtn.classList.add("button");
  fsBtn.innerText = "Full Screen";
  fsDiv.append(fsBtn);

  webSplashInner.innerHTML = "";
  webSplashInner.classList.add('web-splash-loading');

  await loadGodot({
    basePath: "./demo-game",
    executable: "index",
    canvas: webSplashInner,
  }).catch(err => {
    console.error("Godot failed to start:", err);
  });

  webSplashInner.classList.remove('web-splash-loading');
  webSplashInner.classList.remove('base-background');
  webSplashInner.appendChild(fsDiv);
  fsBtn.addEventListener("click", fullscreenDemoGame);
};

demoButton.addEventListener('click', loadDemoGame);
