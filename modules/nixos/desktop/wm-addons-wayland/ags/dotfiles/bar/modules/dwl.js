import GLib from "gi://GLib";
import { range } from "../../utils/index.js";
import { spacing } from "../constants.js";
import { mapAppId } from "../utils.js";

// NOTE: personal preference, I like to have only one bar
const mainOutputName = GLib.getenv("MAIN_OUTPUT_NAME") || "";

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
    `dwl-state '${mainOutputName}' visible_appids`,
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
    class_name: "wmtaskbar",
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
        `dwl-state '${mainOutputName}' ${i}`,
        (out) => {
          return JSON.parse(out);
        },
      ],
    },
  ),
);

export const dwltags = () =>
  Widget.Box({
    class_name: "wmtags",
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
  cmd: `dwl-state '${mainOutputName}' title`,
  className: "wmtitle",
  labelAttrs: {
    truncate: "middle",
  },
});

export const dwllayout = generateScriptModule({
  cmd: `dwl-state '${mainOutputName}' layout`,
  className: "dwllayout",
});

export const dwlmode = generateScriptModule({
  cmd: `dwl-state '${mainOutputName}' mode`,
  className: "wmmode",
});

const DwlScratchpads = Variable(0, {
  listen: [
    `dwl-state '${mainOutputName}' scratchpads_count`,
    (out) => parseInt(JSON.parse(out).text),
  ],
});
export const dwlscratchpads = () =>
  Widget.Label({
    class_name: "wmscratchpads",
    label: DwlScratchpads.bind().as((value) => `  ${value}`),
    visible: DwlScratchpads.bind().as((value) => !!value),
    tooltip_text: "scratchpads count",
  });

const DwlNamedscratchpads = Variable(0, {
  listen: [
    `dwl-state '${mainOutputName}' namedscratchpads_count`,
    (out) => parseInt(JSON.parse(out).text),
  ],
});
export const dwlnamedscratchpads = () =>
  Widget.Label({
    class_name: "wmnamedscratchpads",
    label: DwlNamedscratchpads.bind().as((value) => `  ${value}`),
    visible: DwlNamedscratchpads.bind().as((value) => !!value),
    tooltip_text: "namedscratchpads count",
  });

export const IsMainOutputFocused = Variable(0, {
  listen: [
    `dwl-state '${mainOutputName}' selmon`,
    (out) => !!parseInt(JSON.parse(out).text),
  ],
});

