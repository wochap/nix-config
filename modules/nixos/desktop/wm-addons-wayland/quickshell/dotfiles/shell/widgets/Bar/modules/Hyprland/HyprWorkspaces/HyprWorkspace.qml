import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.services
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import "../Utils.js" as Utils

Button {
  id: root

  required property var clients
  required property int index
  required property var workspace
  required property HyprlandMonitor monitor
  required property bool occupied
  property int workspaceId: index + 1
  property bool focused: monitor?.activeWorkspace?.id === workspaceId
  property var lastClient: SHyprland.clientsByAddress[root.workspace?.lastwindow]
  property bool hasLastClient: !!root.lastClient

  onClicked: Hyprland.dispatch(`workspace ${workspaceId}`)
  verticalPadding: 0
  horizontalPadding: root.focused && clients.length > 0 ? 3 : 6
  background: Rectangle {
    color: focused ? Theme.options.surface0 : "transparent"
    radius: ConfigBar.modulesRadius
  }
  contentItem: Loader {
    sourceComponent: root.focused && clients.length > 0 ? taskbar : number
  }

  Component {
    id: number

    ColumnLayout {
      spacing: -(Styles.font.pixelSize.small / 2)

      SystemIcon {
        Layout.alignment: Qt.AlignHCenter
        visible: root.hasLastClient
        icon: Utils.mapAppId(root.lastClient?.class ?? "")
        size: Styles.font.pixelSize.normal
        layer.enabled: root.lastClient?.floating ?? false
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowBlur: 0.25
          shadowColor: Theme.options.primary
        }
      }

      StyledText {
        id: styledText

        Layout.alignment: Qt.AlignHCenter
        color: focused && occupied ? Theme.options.primary : (occupied ? Theme.options.text : Theme.options.textDimmed)
        text: workspaceId
        font.pixelSize: root.hasLastClient ? Styles.font.pixelSize.smaller : Styles.font.pixelSize.normal
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
          opacity: modelData.focused ? 1 : 0.5
          layer.enabled: modelData.floating
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.25
            shadowColor: Theme.options.primary
          }
        }
      }
    }
  }
}
