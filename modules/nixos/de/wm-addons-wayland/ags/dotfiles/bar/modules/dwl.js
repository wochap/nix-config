import { range } from "../../utils/index.js";

const title = Variable(
  { text: "" },
  {
    listen: [`bash -c "dwl-waybar '' title"`, (out) => JSON.parse(out)],
  },
);
const layout = Variable(
  { text: "" },
  {
    listen: [`bash -c "dwl-waybar '' layout"`, (out) => JSON.parse(out)],
  },
);
const mode = Variable(
  { text: "" },
  {
    listen: [`bash -c "dwl-waybar '' mode"`, (out) => JSON.parse(out)],
  },
);
const tags = range(8, 0).map((i) =>
  Variable(
    { text: "", class: [] },
    { listen: [`bash -c "dwl-waybar '' ${i}"`, (out) => JSON.parse(out)] },
  ),
);

export const dwltitle = () =>
  Widget.Box({
    class_name: "dwltitle",
    child: Widget.Label({
      label: title.bind().as((value) => value.text),
    }),
    visible: title.bind().as((value) => !!value.text),
  });

export const dwllayout = Widget.Label({
  class_name: "dwllayout",
  label: layout.bind().as((value) => value.text),
});

// HACK: without using a function initial `visible` won't work
export const dwlmode = () =>
  Widget.Label({
    class_name: "dwlmode",
    label: mode.bind().as((value) => value.text),
    visible: mode.bind().as((value) => !!value.text),
  });

export const dwltags = Widget.Box({
  class_name: "dwltags",
  children: tags.map((tag) =>
    Widget.Label({
      label: tag.bind().as((value) => value.text),
      class_names: tag.bind().as((value) => value.class),
    }),
  ),
});
