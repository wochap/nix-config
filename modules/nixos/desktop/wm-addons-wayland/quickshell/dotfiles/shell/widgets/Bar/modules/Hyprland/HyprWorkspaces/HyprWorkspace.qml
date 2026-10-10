import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config
import qs.Woints

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

  Accessible.name: `Workspace ${root.workspaceId}`
  Accessible.checkable: true
  Accessible.checked: root.isFocused
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

  Hintable {
    target: root
    label: root.Accessible.name
    onActivated: root.clicked()
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

          MouseArea {
            id: clientMouseArea

            readonly property string label: modelData.title || modelData.class

            // temporarily force cursor.no_warps so focusing doesn't move the cursor
            function focusClient() {
              const window = `"address:${modelData.address}"`;
              const raise = modelData.floating ? `hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = ${window} }))` : "";
              Quickshell.execDetached(["hyprctl", "eval", `
                local no_warps = hl.get_config("cursor.no_warps")
                hl.config({ cursor = { no_warps = true } })
                hl.dispatch(hl.dsp.focus({ window = ${window} }))
                ${raise}
                hl.config({ cursor = { no_warps = no_warps } })
              `]);
            }

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clientMouseArea.focusClient()
            Accessible.role: Accessible.Button
            Accessible.name: clientMouseArea.label
            Accessible.checkable: true
            Accessible.checked: modelData.isFocused
            Accessible.onPressAction: clientMouseArea.focusClient()

            Hintable {
              label: clientMouseArea.label
              onActivated: clientMouseArea.focusClient()
            }
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
