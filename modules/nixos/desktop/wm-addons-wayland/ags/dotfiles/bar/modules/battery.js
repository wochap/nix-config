const Battery = await Service.import("battery");

export const battery = Widget.Label({
  useMarkup: true,
  visible: Battery.bind("available"),
  class_names: Utils.merge(
    [
      Battery.bind("percent"),
      Battery.bind("charging"),
      Battery.bind("charged"),
      Battery.bind("energy-rate"),
    ],
    (percent, charging, charged, energyRate) => {
      return [
        "battery",
        charging ? "charging" : "",
        charged ? "charged" : "charged",
        charged ? "charged" : "charged",
        energyRate > 0 ? "discharging" : "",
        percent < 15 ? "critical" : "",
      ];
    },
  ),
  label: Utils.merge(
    [
      Battery.bind("percent"),
      Battery.bind("charging"),
      Battery.bind("charged"),
    ],
    (percent, charging, charged) => {
      if (charging) {
        return `<span rise='-1000'></span> ${percent}%`;
      }
      return `<span rise='-1000'></span> ${percent}%`;
    },
  ),
});
