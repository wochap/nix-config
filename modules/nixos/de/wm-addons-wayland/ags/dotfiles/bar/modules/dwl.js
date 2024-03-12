import { range } from "../../utils/index.js";

const generateScriptModule = ({ cmd, className }) => {
  const variable = Variable(
    { text: "", class: [] },
    {
      listen: [cmd, (out) => JSON.parse(out)],
    },
  );
  // HACK: without using a function initial `visible` won't work
  return () =>
    Widget.Label({
      class_name: className,
      label: variable.bind().as((value) => value.text),
      visible: variable.bind().as((value) => !!value.text),
    });
};

const tags = range(8, 0).map((i) =>
  Variable(
    { text: "", class: [] },
    { listen: [`dwl-waybar '' ${i}`, (out) => JSON.parse(out)] },
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

export const dwltitle = generateScriptModule({
  cmd: "dwl-waybar '' title",
  className: "dwltitle",
});

export const dwllayout = generateScriptModule({
  cmd: "dwl-waybar '' layout",
  className: "dwllayout",
})();

export const dwlmode = generateScriptModule({
  cmd: "dwl-waybar '' mode",
  className: "dwlmode",
});
