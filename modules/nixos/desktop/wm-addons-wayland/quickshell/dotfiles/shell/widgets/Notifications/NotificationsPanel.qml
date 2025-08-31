import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.services
import qs.services.SNotifications

PanelWindow {
  id: root

  WlrLayershell.namespace: "quickshell:notifications-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    right: true
    bottom: true
  }
  exclusionMode: ExclusionMode.Ignore
  visible: true
  exclusiveZone: 0
  implicitWidth: 460
  color: "#5cffffff"

  ColumnLayout {

    Repeater {
      model: SNotifications.list

      Text {
        text: JSON.stringify(modelData)
      }
    }
  }
}
