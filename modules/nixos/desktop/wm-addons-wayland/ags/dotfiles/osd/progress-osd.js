import { Progress } from "./widgets/Progress.js";

const ProgressFifo = Variable(0, {
  listen: [
    [
      "bash",
      "-c",
      `while true; do if read -r line < /run/user/$UID/progress_osd; then echo "$line"; fi; done`,
    ],
    (out) => parseInt(out),
  ],
});
const ProgressIconFifo = Variable(0, {
  listen: [
    [
      "bash",
      "-c",
      `while true; do if read -r line < /run/user/$UID/progress_icon_osd; then echo "$line"; fi; done`,
    ],
  ],
});

export const progressOsd = () => {
  const progressIcon = Widget.Label({
    class_name: "icon",
  });
  const progress = Progress({
    width: 234,
    height: 31,
    vertical: false,
    child: progressIcon,
  });

  const progressRevealer = Widget.Revealer({
    revealChild: false,
    transition: "none",
    child: progress,
  });

  let count = 0;
  ProgressFifo.connect("changed", ({ value }) => {
    progress.setValue(value / 100);
    progressRevealer.reveal_child = true;
    count++;
    Utils.timeout(1000, () => {
      count--;
      if (count === 0) {
        progressRevealer.reveal_child = false;
      }
    });
  });
  ProgressIconFifo.connect("changed", ({ value }) => {
    progressIcon.label = value;
  });

  return Widget.Box({
    class_name: "progress-osd",
    hpack: "center",
    vpack: "start",
    expand: true,
    children: [progressRevealer],
  });
};
