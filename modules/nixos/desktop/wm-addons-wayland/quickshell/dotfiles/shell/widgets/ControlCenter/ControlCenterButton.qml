import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.widgets.common

ColumnLayout {
  id: root

  property string label: ""
  property string systemIcon: ""
  property string materialIcon: ""
  property string woosIcon: ""
  property bool isActive: false
  property string bg: isActive ? Theme.options.primary : Theme.options.surface1
  property string borderColor: isActive ? Qt.darker(Theme.options.primary, 1.25) : Theme.options.surface0
  property string fg: isActive ? Theme.options.base : Theme.options.text
  property real lighterIncrement: isActive ? 1.1 : 1.25

  signal clicked

  Button {
    id: button

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 50
    padding: 0
    background: StyledRect {
      color: button.hovered ? Qt.lighter(root.bg, root.lighterIncrement) : root.bg
      radius: 4

      InnerBorder {
        color: root.hovered ? Qt.lighter(root.borderColor, root.lighterIncrement) : root.borderColor
        innerRadius: 2
        radius: 3
        bottomThickness: 1
      }
    }
    contentItem: Loader {
      sourceComponent: root.systemIcon.length > 0 ? systemIconComponent : root.materialIcon.length > 0 ? materialIconComponent : woosIconComponent
    }
    onClicked: {
      root.clicked();
    }

    Component {
      id: systemIconComponent

      Item {
        SystemIcon {
          anchors.centerIn: parent
          icon: root.systemIcon
          size: 30
          enableColoriser: true
          color: root.fg
        }
      }
    }

    Component {
      id: materialIconComponent

      Item {
        MaterialIcon {
          anchors.centerIn: parent
          icon: root.materialIcon
          size: 20
          color: root.fg
          weight: Font.Light
        }
      }
    }

    Component {
      id: woosIconComponent

      Item {
        WoosIcon {
          // TODO: move a little to the left
          anchors.centerIn: parent
          icon: root.woosIcon
          size: Styles.font.pixelSize.larger
          color: root.fg
        }
      }
    }
  }

  StyledText {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.label
    elide: Text.ElideMiddle
    // font.pixelSize: Styles.font.pixelSize.small
  }
}
