const Bluetooth = await Service.import("bluetooth");

export const bluetooth = Widget.Label({
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
          return `󰂱 ${connectedDevices.length}`;
        }
        return "󰂯";
      }
      return "󰂲";
    },
  ),
});
