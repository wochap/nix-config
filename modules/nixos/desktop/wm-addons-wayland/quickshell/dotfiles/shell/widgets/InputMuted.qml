import QtQuick
import qs.services
import qs.widgets.common

Item {
  OsdStatus {
    service: SPipewire
    serviceSignalName: "isInputMutedChanged"
    serviceFlagKey: "isInputMuted"
    namespace: "quickshell:input-mute-osd"
    iconOff: ""
    iconOn: ""
  }
}
