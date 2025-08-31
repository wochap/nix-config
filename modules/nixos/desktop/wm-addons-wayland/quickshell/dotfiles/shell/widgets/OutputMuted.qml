import QtQuick
import qs.services
import qs.widgets.common

Item {
  OsdStatus {
    service: SPipewire
    serviceSignalName: "isOutputMutedChanged"
    serviceFlagKey: "isOutputMuted"
    namespace: "quickshell:output-mute-osd"
    iconOff: ""
    iconOn: ""
  }
}
