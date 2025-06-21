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
  dwlnamedscratchpads,
  dwltaskbar,
  IsOutputFocused,
} from "./modules/dwl.js";
import {
  hyprlandTitle,
  hyprlandLayout,
  hyprlandWorkspaces,
  hyprlandNamedScratchpads,
  hyprlandScratchpads,
  hyprlandMode,
  hyprlandTaskbar,
  hyprlandBarClass,
} from "./modules/hyprland.js";
import { matcha } from "./modules/matcha.js";
import { network } from "./modules/network.js";
import { offlinemsmtp } from "./modules/offlinemsmtp.js";
import { recorder } from "./modules/recorder.js";
import { systray } from "./modules/systray.js";
import { temperature } from "./modules/temperature.js";
import { timewarrior } from "./modules/timewarrior.js";
import { wireguard } from "./modules/wireguard.js";
import { spacing } from "./constants.js";

// HACK: without wrapping bar in a function
// bar will be visible before our CSS is loaded
// making the bar look BAD for the first few seconds
export const bar = (gdkMonitorId, monitorPlugName) => {
  const XDG_SESSION_DESKTOP = Utils.exec(`sh -c 'echo "$XDG_SESSION_DESKTOP"'`);
  const isDwl = XDG_SESSION_DESKTOP === "dwl";
  const isHyprland = XDG_SESSION_DESKTOP === "Hyprland";

  let leftModules = [];
  let centerModules = [];
  let className = "bar-container";
  if (isDwl) {
    leftModules = [
      dwltags(monitorPlugName),
      dwllayout(monitorPlugName),
      dwlnamedscratchpads(monitorPlugName),
      dwlscratchpads(monitorPlugName),
      dwlmode(monitorPlugName),
      capslock(monitorPlugName),
      // dwltitle(monitorPlugName),
    ];
    centerModules = [dwltaskbar(monitorPlugName)];
    className = IsOutputFocused(monitorPlugName)
      .bind()
      .as((value) => `bar-container ${value ? "focused" : ""}`);
  } else if (isHyprland) {
    const HYPRLAND_INSTANCE_SIGNATURE = Utils.exec(
      `sh -c 'echo "$HYPRLAND_INSTANCE_SIGNATURE"'`,
    );
    leftModules = [
      hyprlandWorkspaces(),
      hyprlandLayout(monitorPlugName, HYPRLAND_INSTANCE_SIGNATURE),
      hyprlandNamedScratchpads(),
      hyprlandScratchpads(),
      hyprlandMode(),
      capslock(),
      hyprlandTitle(),
    ];
    centerModules = [hyprlandTaskbar()];
    className = hyprlandBarClass(monitorPlugName);
  }

  return Widget.Window({
    name: `bar-${monitorPlugName}`,
    monitor: gdkMonitorId,
    class_name: className,
    exclusivity: "exclusive",
    layer: isDwl ? "top" : "bottom",
    anchor: ["top", "left", "right"],
    child: Widget.CenterBox({
      class_name: "bar loading",
      spacing,
      setup(self) {
        setTimeout(() => {
          self.toggleClassName("loading", false);
        }, 250);
      },
      startWidget: Widget.Box({
        spacing,
        children: leftModules,
      }),
      centerWidget: Widget.Box({
        hpack: "center",
        children: centerModules,
      }),
      endWidget: Widget.Box({
        spacing,
        hpack: "end",
        children: [
          systray(),
          wireguard(),
          recorder(),
          matcha(),
          offlinemsmtp(),
          temperature(),
          timewarrior(),
          dunst(),
          battery(),
          audio(),
          bluetooth(),
          network(),
          clock(),
        ],
      }),
    }),
  });
};
