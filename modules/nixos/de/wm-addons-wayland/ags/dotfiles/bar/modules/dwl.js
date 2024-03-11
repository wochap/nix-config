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

export const dwltags = Widget.Box({
  class_name: "dwltags",
  children: tags.map((tag) =>
    Widget.Label({
      label: tag.bind().as((value) => value.text),
      class_names: tag.bind().as((value) => value.class),
    }),
  ),
});
