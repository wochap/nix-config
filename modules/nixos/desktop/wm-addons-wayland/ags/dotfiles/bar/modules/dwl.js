import { range } from "../../utils/index.js";
import { spacing } from "../constants.js";
import { mapAppId } from "../utils.js";

const generateScriptModule = ({ cmd, className, labelAttrs }) => {
  const Var = Variable(
    { text: "" },
    {
      listen: [cmd, (out) => JSON.parse(out)],
    },
  );
  // HACK: without using a function initial `visible` won't work
  return () =>
    Widget.Label({
      class_name: className,
      label: Var.bind().as((value) => value.text.replace(/\n/g, " ")),
      visible: Var.bind().as((value) => !!value.text),
      ...labelAttrs,
    });
};

const VisibleAppIds = Variable([], {
  listen: [
    "dwl-state '' visible_appids",
    (out) => {
      const items = JSON.parse(out)
        .text.split(" ")
        .filter((str) => str.trim().length);
      const result = [];
      for (let i = 0; i < items.length; i += 2) {
        const appId = mapAppId(items[i]);
        result.push({
          appId,
          focused: items[i + 1] === "true",
        });
      }
      return result;
    },
  ],
});
export const dwltaskbar = () =>
  Widget.Box({
    class_name: "taskbar",
    spacing,
    // HACK: using binding `visible` property doesn't work
    setup(self) {
      self.hook(VisibleAppIds, () => {
        self.visible = VisibleAppIds.value.length > 0;
      });
    },
    children: VisibleAppIds.bind().as((visibleAppIds) => {
      return visibleAppIds.map(({ appId, focused }) =>
        Widget.Box({
          tooltip_text: appId,
          class_name: focused ? "focused" : "",
          child: Widget.Icon({
            icon: appId,
            size: 24,
          }),
        }),
      );
    }),
  });

const tags = range(9, 0).map((i) =>
  Variable(
    {
      text: "",
      occupied: false,
      activated: false,
      focused: false,
      urgent: false,
    },
    {
      listen: [
        `dwl-state '' ${i}`,
        (out) => {
          return JSON.parse(out);
        },
      ],
    },
  ),
);

export const dwltags = () =>
  Widget.Box({
    class_name: "dwltags",
    spacing,
    children: tags.map((tag) =>
      Widget.Label({
        label: tag.bind().as((value) => value.text),
        class_names: tag.bind().as((value) =>
          Object.entries(value)
            .filter(([_, val]) => val === true)
            .map(([key]) => key),
        ),
      }),
    ),
  });

export const dwltitle = generateScriptModule({
  cmd: "dwl-state '' title",
  className: "dwltitle",
  labelAttrs: {
    truncate: "middle",
  },
});

export const dwllayout = generateScriptModule({
  cmd: "dwl-state '' layout",
  className: "dwllayout",
});

export const dwlmode = generateScriptModule({
  cmd: "dwl-state '' mode",
  className: "dwlmode",
});

const Dwlscratchpads = Variable(0, {
  listen: [
    "dwl-state '' namedscratchpads_count",
    (out) => parseInt(JSON.parse(out).text),
  ],
});
export const dwlscratchpads = () =>
  Widget.Label({
    class_name: "dwlscratchpads",
    label: Dwlscratchpads.bind().as((value) => `  ${value}`),
    visible: Dwlscratchpads.bind().as((value) => !!value),
    tooltip_text: "scratchpads count",
  });
