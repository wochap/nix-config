import QtQuick
import qs.services
import qs.widgets.common

OsdProgress {
  service: SBacklight
  serviceSignalName: "changed"
  serviceValueKey: "percentage"
  namespace: "quickshell:backlight-osd"
  icon: "sunny"
}
