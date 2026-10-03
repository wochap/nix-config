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
    materialIconOn: "volume_off"
    materialIconOff: "volume_up"
    colorOn: Theme.options.peach
  }
}
