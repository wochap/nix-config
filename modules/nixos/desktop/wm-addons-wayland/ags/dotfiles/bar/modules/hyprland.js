import { range } from "../../utils/index.js";
import { spacing } from "../constants.js";
import { mapAppId } from "../utils.js";

let Hyprland;

try {
  Hyprland = await Service.import("hyprland");
} catch (error) {
  console.log(error);
}

export const hyprlandTitle = () =>
  Widget.Box({
    className: "wmtitle",
    spacing: 0,
    homogeneous: true,
    vertical: true,
    children: [
      Widget.Label({
        class_name: "wmtitle_appid",
        label: Hyprland.active.client.bind("class"),
        visible: Hyprland.active.client.bind("address").as((addr) => !!addr),
        truncate: "middle",
        xalign: 0,
      }),
      Widget.Label({
        class_name: "wmtitle_title",
        label: Hyprland.active.client.bind("title"),
        visible: Hyprland.active.client.bind("address").as((addr) => !!addr),
        truncate: "middle",
        xalign: 0,
      }),
    ],
  });

export const hyprlandLayout = (monitorPlugName, HYPRLAND_INSTANCE_SIGNATURE) =>
  Widget.Label({
    className: "wmlayout",
    tooltip_text: "layout",
    setup(self) {
      self.hook(Hyprland, async () => {
        const is_ws_monocle = await Utils.execAsync([
          "bash",
          "-c",
          `[ -f "/tmp/hyprland-${monitorPlugName}-monocle-ws-${HYPRLAND_INSTANCE_SIGNATURE}" ] && grep -qxF "${Hyprland.active.workspace.id}" "/tmp/hyprland-${monitorPlugName}-monocle-ws-${HYPRLAND_INSTANCE_SIGNATURE}" && echo true || echo false`,
        ]);
        if (is_ws_monocle === "true") {
          self.visible = true;
          self.label = "[M]";
        } else {
          self.label = "";
          self.visible = false;
        }
      });
    },
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
            const occupied = (wsData?.windows ?? 0) > 0;
            const focused = Hyprland.active.workspace.id == ws;
            self.class_name = `${occupied ? "occupied" : ""} ${focused ? "activated" : ""} ${occupied && focused ? "focused" : ""}`;
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
        (_, submap = "") => {
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
          `hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:tmpscratchpads")] | length'`,
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
    spacing: spacing / 2,
    setup(self) {
      self.hook(Hyprland, () => {
        const activeAddress = Hyprland.active.client.address;
        const visibleAppIds = Hyprland.clients
          .filter(
            (c) =>
              c.mapped && c.workspace.name === Hyprland.active.workspace.name,
          )
          .map((c) => ({
            appIdOriginal: c.class,
            appId: mapAppId(c.class),
            focused: c.address === activeAddress,
            floating: c.floating,
          }));
        self.children = visibleAppIds.map(
          ({ appId, focused, floating, appIdOriginal }) => {
            const _appId = appId.trim() || "unknown";
            return Widget.Box({
              tooltip_text: appIdOriginal,
              class_name: `${focused ? "focused" : ""} ${floating ? "floating" : ""}`,
              child: Widget.Icon({
                icon: _appId,
                size: 32,
              }),
            });
          },
        );
        self.visible = visibleAppIds.length > 0;
      });
    },
  });

export const hyprlandBarClass = (monitorPlugName) => {
  return Hyprland.active.monitor.bind("name").as((name) => {
    const focused = name === monitorPlugName;
    return `bar-container ${focused ? "focused" : ""}`;
  });
};
