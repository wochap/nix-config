pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

Singleton {
  id: root

  property bool available: UPower.displayDevice.isLaptopBattery
  property var chargeState: UPower.displayDevice.state
  property bool isCharging: chargeState == UPowerDeviceState.Charging
  property bool isFullyCharged: chargeState == UPowerDeviceState.FullyCharged
  property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
  property real percentage: UPower.displayDevice.percentage
  property real energyRate: UPower.displayDevice.changeRate
  property real timeToEmpty: UPower.displayDevice.timeToEmpty
  property real timeToFull: UPower.displayDevice.timeToFull
  property string batteryIcon: getIcon()
  property string batteryIconColor: getIconColor()
  property string batteryLabel: getLabel()

  function getIcon() {
    const percent = root.percentage * 100;
    if (!root.available) {
      return "battery-missing";
    }
    if (root.isFullyCharged) {
      return "battery-full-charged";
    }
    if (root.isCharging) {
      const icons = [[100, "battery-full-charging"], [80, "battery-good-charging"], [60, "battery-good-charging"], [40, "battery-low-charging"], [20, "battery-caution-charging"], [0, "battery-caution-charging"]];
      const icon = icons.find(([threshold, _]) => percent >= threshold);
      return icon?.[1] ?? "battery-missing";
    }
    if (root.energyRate < 0.1) {
      return `battery-full-charged`;
    }
    const icons = [[100, "battery-full"], [80, "battery-good"], [60, "battery-good"], [40, "battery-low"], [20, "battery-caution"], [0, "battery-empty"]];
    const icon = icons.find(([threshold, _]) => percent >= threshold);
    return icon?.[1] ?? "battery-missing";
  }

  function getIconColor() {
    const percent = root.percentage * 100;
    if (!root.available) {
      return Theme.options.red;
    }
    if (root.isFullyCharged) {
      return Theme.options.green;
    }
    if (root.isCharging) {
      return Theme.options.text;
    }
    if (root.energyRate < 0.1) {
      return Theme.options.green;
    }
    const iconColors = [[16, Theme.options.text], [15, Theme.options.red], [0, Theme.options.red]];
    const iconColor = iconColors.find(([threshold, _]) => percent >= threshold);
    return iconColor?.[1] ?? Theme.options.red;
  }

  function getLabel() {
    const percent = root.percentage * 100;
    if (!root.available) {
      return "Missing";
    }
    if (root.isFullyCharged) {
      return "Full charged";
    }
    if (root.isCharging) {
      return "Charging";
    }
    if (root.energyRate < 0.1) {
      return "Full charged";
    }
    return "Discharging";
  }
}
