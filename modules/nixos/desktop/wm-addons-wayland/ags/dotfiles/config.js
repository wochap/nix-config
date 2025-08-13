import { forMonitors } from "./utils/index.js";
import { bar } from "./bar/index.js";
import { osd } from "./osd/index.js";

App.config({
  style: "./style.css",
  iconTheme: "Reversal-Extra",
  gtkTheme: "",
});

// HACK: to ensure that our CSS is loaded before widget creation
Utils.timeout(0, () => {
  App.config({
    windows: [...forMonitors(bar), ...forMonitors(osd)],
  });
});

Utils.subprocess(["bash", "-c", "color-scheme watch"], (colorScheme) => {
  const HOME = Utils.exec(`sh -c 'echo "$HOME"'`);
  App.applyCss(`/${HOME}/.config/theme-colors-gtk-${colorScheme}.css`);
});
