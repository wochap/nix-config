import QtQuick
import qs.config
import qs.services
import qs.widgets.common

OsdProgress {
  service: SBacklight
  serviceSignalName: "changed"
  serviceValueKey: "percentage"
  namespace: "quickshell:backlight-osd"
  icon: "display-brightness"
  fillColor: Theme.options.mauve
}
