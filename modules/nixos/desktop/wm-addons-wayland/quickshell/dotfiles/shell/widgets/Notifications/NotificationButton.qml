import QtQuick
import QtQuick.Controls
import qs.config
import qs.widgets.common

Button {
  id: root

  property string materialIcon: ""
  property int materialIconSize: Styles.font.pixelSize.normal
  property int textSize: Styles.font.pixelSize.smaller
  property string fg: Theme.options.text
  property string bg: Theme.options.surface0
  property string borderColor: Theme.options.surface1

  verticalPadding: 0
  horizontalPadding: 2
  scale: pressed ? 0.9 : 1.0
  background: StyledRect {
    color: root.hovered ? Qt.lighter(root.bg, 1.25) : root.bg
    radius: 2

    InnerBorder {
      color: root.hovered ? Qt.lighter(root.borderColor, 1.25) : root.borderColor
      innerRadius: 2
      radius: 3
      topThickness: 1
    }
  }
  contentItem: Loader {
    sourceComponent: root.materialIcon.length > 0 ? materialIconComponent : textComponent
  }

  Behavior on scale {
    NumberAnimation {
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }

  Component {
    id: materialIconComponent

    MaterialIcon {
      icon: root.materialIcon
      size: root.materialIconSize
      color: root.fg
      weight: Font.Light
    }
  }

  Component {
    id: textComponent

    StyledText {
      text: root.text
      font.pixelSize: root.textSize
      color: root.fg
    }
  }
}
