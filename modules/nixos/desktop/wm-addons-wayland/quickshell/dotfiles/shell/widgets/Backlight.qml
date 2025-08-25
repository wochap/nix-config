import QtQuick

import qs.services
import qs.widgets.common

Osd {
  service: Backlight
  serviceSignalName: "changed"
  serviceValueKey: "percentage"
  namespace: "quickshell:backlight-osd"
  icon: "sunny"
}
