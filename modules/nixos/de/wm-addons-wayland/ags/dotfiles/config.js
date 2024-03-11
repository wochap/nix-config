// const audio = await Service.import("audio");
// const battery = await Service.import("battery");
// const bluetooth = await Service.import("bluetooth");

import { bar } from "./bar/index.js";

App.config({
  style: "./bar/style.css",
  windows: [bar],
});
