import { spacing } from "../constants.js";

const appIds = ["kitty", "slack", "thunar-scratch", "thunar"];
const activeAppId = "slack";
export const taskbar = Widget.Box({
  class_name: "taskbar",
  spacing,
  children: appIds.map((appId) =>
    Widget.Box({
      tooltip_text: appId,
      class_name: activeAppId === appId ? "focused" : "",
      child: Widget.Icon({
        icon: appId,
        size: 24,
      }),
    }),
  ),
});
