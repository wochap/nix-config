import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Button {
  id: root

  required property var taskBarItems
  required property int index
  required property var workspace
  required property HyprlandMonitor monitor
  required property bool occupied
  property int workspaceId: index + 1
  property bool focused: monitor?.activeWorkspace?.id === workspaceId

  onClicked: Hyprland.dispatch(`workspace ${workspaceId}`)
  verticalPadding: 0
  horizontalPadding: Styles.font.pixelSize.normal * (root.focused && taskBarItems.length > 0 ? 0.2 : 0.4)
  background: Rectangle {
    color: focused ? Theme.options.surface0 : "transparent"
    radius: 4
  }
  contentItem: Loader {
    sourceComponent: root.focused && taskBarItems.length > 0 ? taskbar : number
  }

  Component {
    id: number

    StyledText {
      id: styledText

      color: focused && occupied ? Theme.options.primary : (occupied ? Theme.options.text : Theme.options.textDimmed)
      text: workspaceId
      anchors.centerIn: parent
    }
  }

  Component {
    id: taskbar

    RowLayout {
      spacing: ConfigBar.modulesSpacing / 4

      Repeater {
        model: root.taskBarItems

        delegate: SystemIcon {
          Layout.fillHeight: true

          icon: modelData.customClass
          size: ConfigBar.clientIcon
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
