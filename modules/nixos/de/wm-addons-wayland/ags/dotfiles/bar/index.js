import { clock } from "./modules/clock.js";
import { dwltags, dwllayout, dwlmode } from "./modules/dwl.js";
import { network } from "./modules/network.js";
import { systray } from "./modules/systray.js";
import { taskbar } from "./modules/taskbar.js";
import { spacing } from "./constants.js";

export const bar = Widget.Window({
  name: "bar",
  class_name: "bar-container",
  exclusivity: "exclusive",
  layer: "bottom",
  anchor: ["top", "left", "right"],
  child: Widget.CenterBox({
    class_name: "bar",
    startWidget: Widget.Box({
      spacing,
      children: [dwltags, dwllayout, dwlmode()],
    }),
    centerWidget: Widget.Box({
      hpack: "center",
      children: [taskbar],
    }),
    endWidget: Widget.Box({
      spacing,
      hpack: "end",
      children: [systray, network(), clock],
    }),
  }),
});
