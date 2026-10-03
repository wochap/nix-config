import QtQuick
import qs.config
import qs.services
import qs.widgets.common

OsdStatus {
  service: SCapslock
  serviceSignalName: "isLockChanged"
  serviceFlagKey: "isLock"
  namespace: "quickshell:capslock-osd"
  materialIconOn: "keyboard_capslock"
  colorOn: Theme.options.yellow
  showIconOn: false
}
