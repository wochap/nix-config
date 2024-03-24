import GLib from "gi://GLib";
import { Capslock } from "../variables/Capslock.js";

const capslock = Widget.Box({
  class_name: "capslock",
  child: Widget.Label({
    vpack: "center",
    hpack: "center",
    expand: true,
    label: "󰌎",
  }),
});

const capslockRevealer = Widget.Revealer({
  revealChild: false,
  transition: "none",
  child: capslock,
});

let timeoutId = null;
Capslock.connect("changed", ({ value }) => {
  if (timeoutId !== null) {
    GLib.source_remove(timeoutId);
    timeoutId = null;
  }
  const hasCapslock = !!value.text;
  capslock.class_name = `capslock ${hasCapslock ? "locked" : "unlocked"}`;
  if (!hasCapslock) {
    capslockRevealer.reveal_child = false;
    return;
  }
  capslockRevealer.reveal_child = true;
  timeoutId = Utils.timeout(1000, () => {
    capslockRevealer.reveal_child = false;
  });
});

export const capslockOsd = Widget.Box({
  class_name: "capslock-osd",
  hpack: "center",
  vpack: "end",
  expand: true,
  children: [capslockRevealer],
});
