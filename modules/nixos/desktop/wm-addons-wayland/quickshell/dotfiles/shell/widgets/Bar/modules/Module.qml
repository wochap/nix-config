import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config
import qs.widgets.Bar.config
import qs.widgets.common

WrapperRectangle {
  id: root

  property real paddingX: ConfigBar.modulesPaddingX
  property string fgColor: Theme.options.text
  property string bgColor: Theme.options.surface0
  property string label: ""
  property string icon: ""
  property string materialIcon: ""
  property int iconSize
  property string iconSystem: ""
  property int spacing: 8

  leftMargin: paddingX
  rightMargin: paddingX
  color: bgColor
  radius: 4

  RowLayout {
    spacing: root.spacing

    SystemIcon {
      icon: root.iconSystem
      visible: root.iconSystem.length > 0
      size: Styles.font.pixelSize.hugeass
    }

    WoosIcon {
      icon: root.icon
      visible: root.icon.length > 0
      color: root.fgColor
      size: root.iconSize
    }

    MaterialIcon {
      icon: root.materialIcon
      visible: root.materialIcon.length > 0
      color: root.fgColor
      size: root.iconSize
    }

    StyledText {
      id: labelText

      text: root.label
      visible: root.label.length > 0
      color: root.fgColor
      verticalAlignment: Text.AlignVCenter
    }
  }
}
