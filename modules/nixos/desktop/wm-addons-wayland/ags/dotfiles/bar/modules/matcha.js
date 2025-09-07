const Idle = Variable(
  { text: "", class: "" },
  {
    poll: [
      1000,
      ["bash", "-c", "shell-idle-inhibit --status"],
      (out) => JSON.parse(out),
    ],
  },
);

export const matcha = () =>
  Widget.Button({
    class_names: Idle.bind().as((value) => [
      "matcha",
      value ? "enabled" : "disabled",
    ]),
    visible: Idle.bind().as((value) => value),
    on_clicked: () => {
      Utils.execAsync(["bash", "-c", "shell-idle-inhibit --toggle"]);
    },
    child: Widget.Label({
      label: "",
    }),
  });
