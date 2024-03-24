const Recorder = Variable(false, {
  poll: [
    1000,
    () => {
      return Utils.execAsync("pgrep wl-screenrec")
        .then((out) => !!out)
        .catch((err) => false);
    },
  ],
});

export const recorder = () => {
  return Widget.Button({
    visible: Recorder.bind(),
    class_names: Recorder.bind().as((value) => [
      "recorder",
      value ? "recording" : "",
    ]),
    on_clicked: () => Utils.execAsync("recorder --area"),
    child: Widget.Label({
      label: "󰑊 REC",
    }),
  });
};
