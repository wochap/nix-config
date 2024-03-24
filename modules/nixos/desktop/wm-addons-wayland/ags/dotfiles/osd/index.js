import { progressOsd } from "./progress-osd.js";
import { capslockOsd } from "./capslock-osd.js";

export const osd = Widget.Window({
  name: "osd",
  class_name: "osd-container",
  layer: "overlay",
  click_through: true,
  anchor: ["top", "bottom", "right", "left"],
  child: Widget.Overlay({
    child: Widget.Box(),
    overlays: [capslockOsd, progressOsd],
  }),
});
