import { range } from "../../utils/index.js";
import { spacing } from "../constants.js";
import { generateScriptModule, mapAppId } from "../utils.js";

let Hyprland;

try {
  Hyprland = await Service.import("hyprland");
} catch (error) {
  console.log(error);
}

export const hyprlandTitle = () =>
  Widget.Label({
    class_name: "wmtitle",
    label: Hyprland.active.client.bind("title"),
    visible: Hyprland.active.client.bind("address").as((addr) => !!addr),
    truncate: "middle",
  });

export const hyprlandWorkspaces = () =>
  Widget.Box({
    class_name: "wmtags",
    spacing,
    children: range(9, 1).map((ws) =>
      Widget.Label({
        label: `${ws}`,
        setup(self) {
          self.hook(Hyprland, () => {
            const wsData = Hyprland.getWorkspace(ws);
            self.class_name = `${(wsData?.windows ?? 0) > 0 ? "occupied" : ""} ${Hyprland.active.workspace.id == ws ? "focused" : ""}`;
          });
        },
      }),
    ),
  });

export const hyprlandMode = () =>
  Widget.Label({
    className: "wmmode",
    setup(self) {
      self.hook(
        Hyprland,
        async (_, submap) => {
          self.label = submap;
          self.visible = !!submap;
        },
        "submap",
      );
      // HACK: only way to hide at start
      setTimeout(() => {
        self.visible = false;
      }, 0);
    },
  });

export const hyprlandScratchpads = () =>
  Widget.Label({
    class_name: "wmscratchpads",
    tooltip_text: "scratchpads count",
    setup(self) {
      self.hook(Hyprland, async () => {
        const count = await Utils.execAsync([
          "bash",
          "-c",
          `hyprctl clients -j | jq '[.[] | select(.workspace.name == "special")] | length'`,
        ]);
        if (count === "0") {
          self.visible = false;
          return;
        }
        self.visible = true;
        self.label = `  ${count}`;
      });
    },
  });

export const hyprlandNamedScratchpads = () =>
  Widget.Label({
    class_name: "wmnamedscratchpads",
    tooltip_text: "namedscratchpads count",
    setup(self) {
      self.hook(Hyprland, async () => {
        const count = await Utils.execAsync([
          "bash",
          "-c",
          `hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:scratchpads")] | length'`,
        ]);
        if (count === "0") {
          self.visible = false;
          return;
        }
        self.visible = true;
        self.label = `  ${count}`;
      });
    },
  });

export const hyprlandTaskbar = () =>
  Widget.Box({
    class_name: "wmtaskbar",
    spacing,
    setup(self) {
      self.hook(Hyprland, () => {
        const visibleAppIds = Hyprland.clients
          .filter(
            (c) =>
              c.mapped && c.workspace.name === Hyprland.active.workspace.name,
          )
          .map((c) => ({
            appId: mapAppId(c.class),
            focused: c.focusHistoryID === 0,
          }));
        self.children = visibleAppIds.map(({ appId, focused }) =>
          Widget.Box({
            tooltip_text: appId,
            class_name: focused ? "focused" : "",
            child: Widget.Icon({
              icon: appId,
              size: 24,
            }),
          }),
        );
        self.visible = visibleAppIds.length > 0;
      });
    },
  });
