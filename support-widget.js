(function () {
  const script = document.createElement("script");

  script.src = "https://storage.ko-fi.com/cdn/scripts/overlay-widget.js";
  script.async = true;
  script.addEventListener("load", function () {
    if (!window.kofiWidgetOverlay) {
      return;
    }

    window.kofiWidgetOverlay.draw("papercraftgames", {
      type: "floating-chat",
      "floating-chat.donateButton.text": "Support FPE",
      "floating-chat.donateButton.background-color": "#fcbf47",
      "floating-chat.donateButton.text-color": "#323842",
    });
  });

  document.body.appendChild(script);
})();
