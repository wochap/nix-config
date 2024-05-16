const Timewarrior = Variable(false, {
  poll: [
    1000,
    [
      "bash",
      "-c",
      `(timew | grep -q "There is no active time tracking." && echo "false") || echo "true"`,
    ],
    (out) => JSON.parse(out),
  ],
});

export const timewarrior = () =>
  Widget.Button({
    class_names: "timewarrior",
    visible: Timewarrior.bind(),
    on_clicked: () => {
      Utils.execAsync(["bash", "-c", "timew stop"]);
    },
    child: Widget.Label({
      useMarkup: true,
      label: "<span rise='-1000'>󱫠</span> <span rise='-1000'></span>",
    }),
  });
