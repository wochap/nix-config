import QtQuick
import qs.config
import qs.services
import qs.widgets.common

Item {
  OsdStatus {
    service: SPipewire
    serviceSignalName: "isInputMutedChanged"
    serviceFlagKey: "isInputMuted"
    namespace: "quickshell:input-mute-osd"
    materialIconOn: "mic_off"
    materialIconOff: "mic"
    colorOn: Theme.options.red
  }
}
