import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend

  readonly property int columns: Math.max(1, Math.floor((width - 2 * ConfigWhichKeys.panelPadding + ConfigWhichKeys.columnSpacing) / (ConfigWhichKeys.minimumCellWidth + ConfigWhichKeys.columnSpacing)))

  screen: backend.screen
  implicitHeight: content.implicitHeight + ConfigWhichKeys.panelPadding + ConfigWhichKeys.bottomMargin
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  mask: Region {}

  anchors {
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.namespace: "quickshell:which-keys"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  ColumnLayout {
    id: content

    anchors {
      fill: parent
      margins: ConfigWhichKeys.panelPadding
      bottomMargin: ConfigWhichKeys.bottomMargin
    }
    spacing: ConfigWhichKeys.rowSpacing

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ConfigWhichKeys.keycapSpacing

      StyledText {
        visible: root.backend.submap.length > 0
        text: root.backend.submap.toUpperCase()
        color: Theme.options.peach
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: Font.Bold
      }

      Repeater {
        model: root.backend.submap.length > 0 ? [] : root.backend.heldModifiers

        delegate: WhichKeysKeycap {
          required property string modelData

          label: modelData
        }
      }
    }

    GridLayout {
      Layout.fillWidth: true
      columns: root.columns
      columnSpacing: ConfigWhichKeys.columnSpacing
      rowSpacing: ConfigWhichKeys.rowSpacing

      Repeater {
        model: root.backend.bindings

        delegate: WhichKeysBinding {
          required property var modelData

          Layout.alignment: Qt.AlignLeft
          keycaps: modelData.keycaps
          description: modelData.description
        }
      }
    }
  }
}
