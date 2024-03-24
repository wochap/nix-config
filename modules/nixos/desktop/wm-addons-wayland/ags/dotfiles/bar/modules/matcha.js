const Matcha = Variable(
  { text: "", class: "" },
  {
    poll: [
      1000,
      ["bash", "-c", "matcha-toggle-mode --read"],
      (out) => JSON.parse(out),
    ],
  },
);

export const matcha = () =>
  Widget.Button({
    class_names: Matcha.bind().as((value) => ["matcha", value.class]),
    visible: Matcha.bind().as((value) => value.class.includes("enabled")),
    on_clicked: () => {
      Utils.execAsync(["bash", "-c", "matcha-toggle-mode --toggle"]);
    },
    child: Widget.Label({
      label: Matcha.bind().as((value) => value.text),
    }),
  });
