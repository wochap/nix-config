const Bluetooth = await Service.import("bluetooth");

export const bluetooth = () =>
  Widget.Label({
    useMarkup: true,
    class_names: Utils.merge(
      [Bluetooth.bind("enabled"), Bluetooth.bind("connected-devices")],
      (enabled, connectedDevices) => {
        return [
          "bluetooth",
          enabled ? "on" : "off",
          connectedDevices.length ? "connected" : "",
        ];
      },
    ),
    label: Utils.merge(
      [Bluetooth.bind("enabled"), Bluetooth.bind("connected-devices")],
      (enabled, connectedDevices) => {
        if (enabled) {
          if (connectedDevices.length) {
            return `<span rise='-1000'></span> ${connectedDevices.length}`;
          }
          return `<span rise='-1000'></span>`;
        }
        return `<span rise='-1000'></span>`;
      },
    ),
  });
