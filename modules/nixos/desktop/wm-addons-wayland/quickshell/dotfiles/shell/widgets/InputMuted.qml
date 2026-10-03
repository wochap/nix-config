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
    systemIconOn: "microphone-sensitivity-muted"
    systemIconOff: "microphone-sensitivity-high"
    colorOn: Theme.options.red
  }
}
