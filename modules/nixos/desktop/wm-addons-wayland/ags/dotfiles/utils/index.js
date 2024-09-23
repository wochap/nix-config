import Gdk from "gi://Gdk";

export function range(length, start = 1) {
  return Array.from({ length }, (_, i) => i + start);
}

const display = Gdk.Display.get_default();
const monitorCount = display?.get_n_monitors() ?? 1;

export function getGdkMonitorPlugName(gdkMonitor) {
  const screen = display?.get_default_screen();
  for (const gdkMonitorId of range(monitorCount, 0)) {
    if (gdkMonitor === display?.get_monitor(gdkMonitorId)) {
      return screen?.get_monitor_plug_name(gdkMonitorId) ?? null;
    }
  }
  return null;
}

export function forMonitors(widget) {
  const monitors = JSON.parse(Utils.exec("wlr-randr --json"));
  const bars = [];
  for (const monitor of monitors) {
    const monitorPlugName = monitor.name;
    // find correct gdkMonitorId
    for (const gdkMonitorId of range(monitorCount, 0)) {
      const gdkMonitor = display?.get_monitor(gdkMonitorId);
      if (getGdkMonitorPlugName(gdkMonitor) === monitorPlugName) {
        bars.push(widget(gdkMonitorId, monitorPlugName));
      }
    }
  }
  return bars.flat(1);
}
