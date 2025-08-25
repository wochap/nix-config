import { progressOsd } from "./progress-osd.js";
import { capslockOsd } from "./capslock-osd.js";

export const osd = (monitor) =>
  Widget.Window({
    name: `osd-${monitor}`,
    monitor,
    class_name: "osd-container",
    layer: "overlay",
    click_through: true,
    anchor: ["top", "bottom", "right", "left"],
    child: Widget.Overlay({
      child: Widget.Box(),
      overlays: [
        capslockOsd(),
        // progressOsd()
      ],
    }),
  });
