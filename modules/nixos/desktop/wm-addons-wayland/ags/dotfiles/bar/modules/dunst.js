const Dunst = Variable(
  { text: "", class: "" },
  {
    poll: [
      1000,
      ["bash", "-c", "dunst-toggle-mode --read"],
      (out) => JSON.parse(out),
    ],
  },
);

export const dunst = Widget.Button({
  class_names: Dunst.bind().as((value) => ["dunst", value.class]),
  on_clicked: () => {
    Utils.execAsync(["bash", "-c", "dunst-toggle-mode --toggle"]);
  },
  child: Widget.Label({
    useMarkup: true,
    label: Dunst.bind().as((value) => value.text),
  }),
});
