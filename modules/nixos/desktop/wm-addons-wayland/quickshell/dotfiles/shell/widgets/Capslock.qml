import QtQuick

import qs.services
import qs.widgets.common

OsdStatus {
  service: CapslockService
  serviceSignalName: "isLockChanged"
  serviceFlagKey: "isLock"
  namespace: "quickshell:capslock-osd"
  iconOn: "keyboard_capslock_badge"
  showIconOn: false
}
