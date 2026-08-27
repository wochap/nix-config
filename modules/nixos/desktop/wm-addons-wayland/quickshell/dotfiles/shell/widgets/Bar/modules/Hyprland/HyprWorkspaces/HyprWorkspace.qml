import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Button {
  id: root

  required property int index
  required property var clients
  required property var workspace
  required property bool isOccupied
  required property HyprlandMonitor hyprlandMonitor
  property int workspaceId: SHyprland.wsOffset + index + 1
  property bool isFocused: hyprlandMonitor?.activeWorkspace?.id === workspaceId
  property var representativeClient: root.clients.find(client => client.address === root.workspace?.lastwindow) ?? root.clients[0] ?? null
  property bool hasRepresentativeClient: !!root.representativeClient

  onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceId}, on_current_monitor = true })`)
  verticalPadding: 0
  horizontalPadding: root.isFocused && clients.length > 0 ? 3 : 6
  background: StyledRect {
    color: root.isFocused ? Theme.options.surface0 : Theme.options.base
    radius: ConfigBar.modulesRadius
  }
  contentItem: Loader {
    sourceComponent: root.isFocused && root.clients.length > 0 ? taskbar : number
  }

  Component {
    id: number

    ColumnLayout {
      spacing: -(Styles.font.pixelSize.small / 2)

      SystemIcon {
        Layout.alignment: Qt.AlignHCenter
        visible: root.hasRepresentativeClient
        icon: root.representativeClient?.customClass ?? ""
        size: Styles.font.pixelSize.normal
        layer.enabled: root.representativeClient?.floating ?? false
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowBlur: 0.25
          shadowColor: Theme.options.primary
        }
      }

      StyledText {
        id: styledText

        Layout.alignment: Qt.AlignHCenter
        color: root.isFocused && root.isOccupied ? Theme.options.primary : (root.isOccupied ? Theme.options.text : Theme.options.textDimmed)
        text: workspaceId
        font.pixelSize: root.hasRepresentativeClient ? Styles.font.pixelSize.smaller : Styles.font.pixelSize.normal
      }
    }
  }

  Component {
    id: taskbar

    RowLayout {
      spacing: 1.5

      Repeater {
        model: root.clients

        delegate: SystemIcon {
          Layout.fillHeight: true
          icon: modelData.customClass
          size: 28
          opacity: modelData.isFocused ? 1 : 0.5
          layer.enabled: modelData.floating
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.25
            shadowColor: Theme.options.primary
          }

          // TODO: doesn't work
          // Behavior on opacity {
          //   NumberAnimation {
          //     duration: 500
          //     easing.type: Easing.InOutQuad
          //   }
          // }
        }
      }
    }
  }
}
