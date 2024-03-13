import { bar } from "./bar/index.js";
import { osd } from "./osd/index.js";

App.config({
  style: "./style.css",
  iconTheme: "Reversal",
  windows: [bar, osd],
});
