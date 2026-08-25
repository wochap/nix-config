import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
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
    spacing: 32

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 16

      StyledText {
        visible: root.backend.submap.length > 0
        text: root.backend.submap.toUpperCase()
        color: Theme.options.peach
        font.pixelSize: Styles.font.pixelSize.small * 2
        font.weight: Font.Bold

        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowBlur: 0.75
          shadowColor: Theme.options.shadow
          shadowHorizontalOffset: 1
          shadowVerticalOffset: 1
        }
      }

      Repeater {
        model: root.backend.submap.length > 0 ? [] : root.backend.heldModifiers

        delegate: RowLayout {
          id: modifierGroup

          required property int index
          required property string modelData
          spacing: 16

          WhichKeysKeycap {
            label: modifierGroup.modelData
            sizeMultiplier: 2
            borderColor: Theme.options.borderSecondary
          }

          StyledText {
            visible: modifierGroup.index < root.backend.heldModifiers.length - 1
            text: "+"
            color: Theme.options.text
            font.pixelSize: Styles.font.pixelSize.small * 2
            font.weight: Font.Bold

            layer.enabled: true
            layer.effect: MultiEffect {
              shadowEnabled: true
              shadowBlur: 0.75
              shadowColor: Theme.options.shadow
              shadowHorizontalOffset: 1
              shadowVerticalOffset: 1
            }
          }
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
