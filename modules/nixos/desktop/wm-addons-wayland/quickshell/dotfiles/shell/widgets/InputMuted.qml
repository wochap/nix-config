import QtQuick

import qs.services
import qs.widgets.common

Item {
  OsdStatus {
    service: Audio
    serviceSignalName: "isInputMutedChanged"
    serviceFlagKey: "isInputMuted"
    namespace: "quickshell:input-mute-osd"
    iconOff: "mic"
    iconOn: "mic_off"
  }
}
