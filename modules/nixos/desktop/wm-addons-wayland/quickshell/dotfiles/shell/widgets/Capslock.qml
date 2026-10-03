import QtQuick
import qs.config
import qs.services
import qs.widgets.common

OsdStatus {
  service: SCapslock
  serviceSignalName: "isLockChanged"
  serviceFlagKey: "isLock"
  namespace: "quickshell:capslock-osd"
  systemIconOn: "capslock-enabled-symbolic"
  systemIconOff: "capslock-disabled-symbolic"
  colorOn: Theme.options.yellow
  showIconOn: false
}
