import { range } from "../../utils/index.js";
import { spacing } from "../constants.js";

const generateScriptModule = ({ cmd, className, labelAttrs }) => {
  const Var = Variable(
    { text: "", class: [] },
    {
      listen: [cmd, (out) => JSON.parse(out)],
    },
  );
  // HACK: without using a function initial `visible` won't work
  return () =>
    Widget.Label({
      class_name: className,
      label: Var.bind().as((value) => value.text),
      visible: Var.bind().as((value) => !!value.text),
      ...labelAttrs,
    });
};

const VisibleAppIds = Variable([], {
  listen: [
    "dwl-waybar '' visible_appids",
    (out) => {
      const items = JSON.parse(out).text.split(" ");
      const result = [];
      for (let i = 0; i < items.length; i += 2) {
        let appId = items[i];
        if (/^kitty-/.test(appId)) {
          appId = "kitty";
        }
        if (/^thunar-/.test(appId)) {
          appId = "thunar";
        }
        if (/^chrome-.*__-Default$/.test(appId)) {
          appId = "google-chrome";
        }
        if (/^msedge-.*-Default$/.test(appId)) {
          appId = "microsoft-edge";
        }
        result.push({
          appId,
          focused: items[i + 1] === "true",
        });
      }
      return result;
    },
  ],
});
export const dwltaskbar = Widget.Box({
  class_name: "taskbar",
  spacing,
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
    { text: "", class: [] },
    { listen: [`dwl-waybar '' ${i}`, (out) => JSON.parse(out)] },
  ),
);

export const dwltags = Widget.Box({
  class_name: "dwltags",
  spacing: 3.5,
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
  labelAttrs: {
    truncate: "middle",
  },
});

export const dwllayout = generateScriptModule({
  cmd: "dwl-waybar '' layout",
  className: "dwllayout",
})();

export const dwlmode = generateScriptModule({
  cmd: "dwl-waybar '' mode",
  className: "dwlmode",
});

const Dwlscratchpads = Variable(0, {
  listen: [
    "dwl-waybar '' namedscratchpads_count",
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
