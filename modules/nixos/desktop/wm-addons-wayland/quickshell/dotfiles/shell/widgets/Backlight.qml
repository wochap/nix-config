import QtQuick
import qs.services
import qs.widgets.common

Osd {
  service: SBacklight
  serviceSignalName: "changed"
  serviceValueKey: "percentage"
  namespace: "quickshell:backlight-osd"
  icon: "sunny"
}
