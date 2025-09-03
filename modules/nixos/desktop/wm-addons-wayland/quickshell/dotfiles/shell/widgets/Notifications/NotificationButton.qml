import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.widgets.common

Button {
  id: root

  property string materialIcon: ""

  verticalPadding: 0
  horizontalPadding: 2
  background: Rectangle {
    color: Theme.options.surface0
    radius: 2
  }
  contentItem: Loader {
    sourceComponent: root.materialIcon.length > 0 ? materialIconComponent : textComponent
  }

  Component {
    id: materialIconComponent

    MaterialIcon {
      icon: root.materialIcon
    }
  }

  Component {
    id: textComponent

    StyledText {
      text: root.text
      font.pixelSize: Styles.font.pixelSize.small
    }
  }
}
