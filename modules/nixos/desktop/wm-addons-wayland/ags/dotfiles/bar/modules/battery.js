const Battery = await Service.import("battery");

export const battery = () =>
  Widget.Label({
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
          charged ? "charged" : "",
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
        Battery.bind("energy-rate"),
      ],
      (percent, charging, charged, energyRate) => {
        if (charged) {
          return `<span size="large" rise='-2050'></span> ${percent}%`;
        }
        if (charging) {
          return `<span size="large" rise='-2050'></span> ${percent}%`;
        }
        if (energyRate === 0) {
          return `<span size="large" rise='-2050'></span> ${percent}%`;
        }
        const icons = [
          [100, ""],
          [80, ""],
          [80, ""],
          [70, ""],
          [60, ""],
          [50, ""],
          [40, ""],
          [30, ""],
          [20, ""],
          [10, ""],
          [0, ""],
        ];
        const icon = icons.find(([threshold, _]) => percent >= threshold)[1];
        return `<span size="large" rise='-2050'>${icon}</span> ${percent}%`;
      },
    ),
  });
