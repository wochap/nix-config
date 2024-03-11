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
      return enabled
        ? `󰂯${connectedDevices.length ? ` ${connectedDevices.length}` : ""}`
        : "󰂲";
    },
  ),
});
