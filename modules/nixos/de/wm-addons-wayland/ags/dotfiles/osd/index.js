import { progressOsd } from "./progress-osd.js";

App.applyCss(
  "/home/gean/nix-config/modules/nixos/de/wm-addons-wayland/ags/dotfiles/osd/style.css",
);

export const osd = Widget.Window({
  name: "osd",
  class_name: "osd-container",
  layer: "overlay",
  click_through: true,
  anchor: ["top", "bottom", "right", "left"],
  child: Widget.Overlay(
    { child: progressOsd },
    // TODO: add capslock osd
  ),
});
