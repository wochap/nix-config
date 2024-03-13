import { bar } from "./bar/index.js";
import { osd } from "./osd/index.js";

App.config({
  style: "./bar/style.css",
  windows: [bar, osd],
});
