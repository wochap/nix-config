import { Progress } from "./widgets/Progress.js";

const ProgressSock = Variable(0, {
  listen: [
    [
      "bash",
      "-c",
      `while true; do if read -r line < /run/user/$UID/ags_osd; then echo "$line"; fi; done`,
    ],
    (out) => parseInt(out),
  ],
});

const progress = Progress({
  width: 31,
  height: 241,
  vertical: true,
});

export const progressRevealer = Widget.Revealer({
  revealChild: false,
  transition: "none",
  child: progress,
});
let count = 0;

ProgressSock.connect("changed", ({ value }) => {
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
