const Capslock = Variable(
  { text: "", class: "" },
  {
    listen: ["capslock", (out) => JSON.parse(out)],
  },
);

// HACK: without using a function initial `visible` won't work
export const capslock = () =>
  Widget.Label({
    // useMarkup: true,
    class_names: Capslock.bind().as((value) => ["capslock", value.class]),
    label: Capslock.bind().as((value) => value.text),
    visible: Capslock.bind().as((value) => !!value.text),
  });
