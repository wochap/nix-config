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

export const dwltaskbar = (monitorPlugName) => {
  const VisibleAppIds = Variable([], {
    listen: [
      `dwl-state "${monitorPlugName}" visible_appids`,
      (out) => {
        const items = JSON.parse(out)
          .text.replace("  ", " unknown ")
          .split(" ")
          .filter((str) => str.trim().length);
        const result = [];
        for (let i = 0; i < items.length; i += 3) {
          const appId = mapAppId(items[i]);
          result.push({
            appId,
            focused: items[i + 1] === "true",
            floating: items[i + 2] === "true",
          });
        }
        return result;
      },
    ],
  });

  return Widget.Box({
    class_name: "wmtaskbar",
    spacing: spacing / 2,
    // HACK: using binding `visible` property doesn't work
    setup(self) {
      self.hook(VisibleAppIds, () => {
        self.visible = VisibleAppIds.value.length > 0;
      });
    },
    children: VisibleAppIds.bind().as((visibleAppIds) => {
      return visibleAppIds.map(({ appId, focused, floating }) =>
        Widget.Box({
          tooltip_text: appId,
          class_name: `${focused ? "focused" : ""} ${floating ? "floating" : ""}`,
          child: Widget.Icon({
            icon: appId,
            size: 32,
          }),
        }),
      );
    }),
  });
};

export const dwltags = (monitorPlugName) => {
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
          `dwl-state '${monitorPlugName}' ${i}`,
          (out) => {
            return JSON.parse(out);
          },
        ],
      },
    ),
  );

  return Widget.Box({
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
};

export const dwltitle = (monitorPlugName) =>
  generateScriptModule({
    cmd: `dwl-state '${monitorPlugName}' title`,
    className: "wmtitle",
    labelAttrs: {
      truncate: "middle",
    },
  })();

export const dwllayout = (monitorPlugName) =>
  generateScriptModule({
    cmd: `dwl-state '${monitorPlugName}' layout`,
    className: "dwllayout",
  })();

export const dwlmode = (monitorPlugName) =>
  generateScriptModule({
    cmd: `dwl-state '${monitorPlugName}' mode`,
    className: "wmmode",
  })();

export const dwlscratchpads = (monitorPlugName) => {
  const DwlScratchpads = Variable(0, {
    listen: [
      `dwl-state '${monitorPlugName}' scratchpads_count`,
      (out) => parseInt(JSON.parse(out).text),
    ],
  });

  return Widget.Label({
    class_name: "wmscratchpads",
    label: DwlScratchpads.bind().as((value) => `  ${value}`),
    visible: DwlScratchpads.bind().as((value) => !!value),
    tooltip_text: "scratchpads count",
  });
};

export const dwlnamedscratchpads = (monitorPlugName) => {
  const DwlNamedscratchpads = Variable(0, {
    listen: [
      `dwl-state '${monitorPlugName}' namedscratchpads_count`,
      (out) => parseInt(JSON.parse(out).text),
    ],
  });

  return Widget.Label({
    class_name: "wmnamedscratchpads",
    label: DwlNamedscratchpads.bind().as((value) => `  ${value}`),
    visible: DwlNamedscratchpads.bind().as((value) => !!value),
    tooltip_text: "namedscratchpads count",
  });
};

export const IsOutputFocused = (monitorPlugName) =>
  Variable(0, {
    listen: [
      `dwl-state '${monitorPlugName}' selmon`,
      (out) => !!parseInt(JSON.parse(out).text),
    ],
  });
