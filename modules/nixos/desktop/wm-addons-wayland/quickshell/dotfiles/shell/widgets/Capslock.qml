import QtQuick

import qs.services
import qs.widgets.common

OsdStatus {
  service: SCapslock
  serviceSignalName: "isLockChanged"
  serviceFlagKey: "isLock"
  namespace: "quickshell:capslock-osd"
  iconOn: "keyboard_capslock_badge"
  showIconOn: false
}
