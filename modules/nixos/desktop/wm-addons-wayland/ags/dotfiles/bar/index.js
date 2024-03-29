import { audio } from "./modules/audio.js";
import { battery } from "./modules/battery.js";
import { bluetooth } from "./modules/bluetooth.js";
import { capslock } from "./modules/capslock.js";
import { clock } from "./modules/clock.js";
import { dunst } from "./modules/dunst.js";
import {
  dwltags,
  dwllayout,
  dwlmode,
  dwltitle,
  dwlscratchpads,
  dwltaskbar,
} from "./modules/dwl.js";
import { matcha } from "./modules/matcha.js";
import { network } from "./modules/network.js";
import { offlinemsmtp } from "./modules/offlinemsmtp.js";
import { recorder } from "./modules/recorder.js";
import { systray } from "./modules/systray.js";
import { temperature } from "./modules/temperature.js";
import { spacing } from "./constants.js";

// HACK: without wrapping bar in a function
// bar will be visible before our CSS is loaded
// making the bar look BAD for the first few seconds
export const bar = () =>
  Widget.Window({
    name: "bar",
    class_name: "bar-container",
    exclusivity: "exclusive",
    layer: "top",
    anchor: ["top", "left", "right"],
    child: Widget.CenterBox({
      class_name: "bar",
      spacing,
      startWidget: Widget.Box({
        spacing,
        children: [
          dwltags,
          dwllayout(),
          dwlscratchpads(),
          dwlmode(),
          capslock(),
          dwltitle(),
        ],
      }),
      centerWidget: Widget.Box({
        hpack: "center",
        children: [dwltaskbar()],
      }),
      endWidget: Widget.Box({
        spacing,
        hpack: "end",
        children: [
          systray,
          recorder(),
          matcha(),
          offlinemsmtp(),
          temperature(),
          dunst,
          battery,
          audio,
          bluetooth,
          network(),
          clock,
        ],
      }),
    }),
  });
