import QtQuick
import qs.config
import qs.services
import qs.widgets.common

Item {
  OsdStatus {
    service: SPipewire
    serviceSignalName: "isOutputMutedChanged"
    serviceFlagKey: "isOutputMuted"
    namespace: "quickshell:output-mute-osd"
    systemIconOn: "audio-volume-muted"
    systemIconOff: "audio-volume-high"
    colorOn: Theme.options.peach
  }
}
