const Network = await Service.import("network");

const wifi = Widget.Label({
  useMarkup: true,
  tooltip_text: Utils.merge(
    [Network.wifi.bind("ssid"), Network.wifi.bind("strength")],
    (ssid, strength) => {
      return `${ssid || "Unknown"} ${strength}%`;
    },
  ),
  setup(self) {
    self.hook(Network.wifi, () => {
      if (Network.wifi.ssid) {
        const icons = [
          [66, ""],
          [44, ""],
          [22, ""],
          [1, ""],
          [0, ""],
        ];
        const percent = Network.wifi.strength;
        const icon = icons.find(([threshold, _]) => percent >= threshold)[1];
        self.class_name = "connected";
        self.label = `<span size="large" rise='-2050'>${icon}</span>`;
      } else {
        self.class_name = "disconnected";
        self.label = `<span size="large" rise='-2050'></span>`;
      }
    });
  },
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
