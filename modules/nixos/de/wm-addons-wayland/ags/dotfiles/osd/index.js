import { progressRevealer } from "./progress-revealer.js";

App.applyCss(
  "/home/gean/nix-config/modules/nixos/de/wm-addons-wayland/ags/dotfiles/osd/style.css",
);

export const osd = Widget.Window({
  name: "osd",
  class_name: "osd-container",
  layer: "overlay",
  click_through: true,
  anchor: ["top", "bottom", "right"],
  child: Widget.Box({
    class_name: "osd",
    vpack: "center",
    children: [progressRevealer],
  }),
});
