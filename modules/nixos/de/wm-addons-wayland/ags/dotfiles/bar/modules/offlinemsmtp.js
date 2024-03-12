const Offlinemsmtp = Variable(
  { text: "", class: "" },
  {
    poll: [1000, "offlinemsmtp-toggle-mode --read", (out) => JSON.parse(out)],
  },
);

export const offlinemsmtp = Widget.Button({
  class_names: Offlinemsmtp.bind().as((value) => ["offlinemsmtp", value.class]),
  on_clicked: () => Utils.execAsync("offlinemsmtp-toggle-mode --toggle"),
  child: Widget.Label({
    label: Offlinemsmtp.bind().as((value) => value.text),
  }),
});
