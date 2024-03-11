const Network = await Service.import("network");

const wifi = Widget.Label({
  label: Network.wifi.bind("internet").as((internet) => {
    if (internet === "connected") {
      return "";
    }
    return "";
  }),
  tooltip_text: Utils.merge(
    [Network.wifi.bind("ssid"), Network.wifi.bind("strength")],
    (ssid, strength) => {
      return `${ssid || "Unknown"} ${strength}%`;
    },
  ),
});

// TODO: implement wired
const wired = Widget.Label({
  label: "wired",
  tooltip_text: "wired",
});

// HACK: return a function so `shown` is respected
export const network = () =>
  Widget.Stack({
    class_names: Network.bind("primary").as((p) => ["network", p || "wifi"]),
    homogeneous: false,
    children: {
      wired: wired,
      wifi: wifi,
    },
    shown: Network.bind("primary").as((p) => p || "wifi"),
    transition: "none",
  });
