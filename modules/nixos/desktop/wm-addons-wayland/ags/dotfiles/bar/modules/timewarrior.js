const Timewarrior = Variable("", {
  poll: [
    1000,
    [
      "bash",
      "-c",
      `timew | grep 'Total' | awk '{split($2, a, ":"); print a[1] ":" a[2]}'`,
    ],
    (out) => out.trim(),
  ],
});

export const timewarrior = () =>
  Widget.Button({
    class_name: "timewarrior",
    visible: Timewarrior.bind().as((value) => value.length > 0),
    on_clicked: () => {
      Utils.execAsync(["bash", "-c", "timew stop"]);
    },
    child: Widget.Label({
      useMarkup: true,
      label: Timewarrior.bind().as(
        (value) =>
          `<span rise='-1000'>󱫠 </span> <span rise='-1000'>${value}</span>`,
      ),
    }),
  });
