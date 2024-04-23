import { forMonitors } from "./utils/index.js";
import { bar } from "./bar/index.js";
import { osd } from "./osd/index.js";

App.config({
  style: "./style.css",
  iconTheme: "Reversal-Extra",
});

// HACK: to ensure that our CSS is loaded before widget creation
Utils.timeout(0, () => {
  App.config({
    windows: [bar(), ...forMonitors(osd)],
  });
});
