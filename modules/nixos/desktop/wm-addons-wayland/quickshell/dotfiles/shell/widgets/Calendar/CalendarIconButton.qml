import QtQuick
import qs.config
import qs.widgets.common
import qs.Woints

// 28px circular (or pill when `label` is set) header button
StyledRect {
  id: root

  property string icon: ""
  property string label: ""
  property string accessibleName: root.label
  property bool isHovered: mouseArea.containsMouse

  signal clicked

  implicitHeight: ConfigCalendar.iconButtonSize
  implicitWidth: root.label.length > 0 ? labelText.implicitWidth + 20 : ConfigCalendar.iconButtonSize
  radius: height / 2
  color: root.isHovered ? Theme.options.surface1 : Theme.options.surface0

  MaterialIcon {
    anchors.centerIn: parent
    visible: root.icon.length > 0
    icon: root.icon
    size: Styles.font.pixelSize.large
    weight: Font.Normal
    color: root.isHovered ? Theme.options.text : Theme.options.subtext1
  }

  StyledText {
    id: labelText

    anchors.centerIn: parent
    visible: root.label.length > 0
    text: root.label
    font.pixelSize: Styles.font.pixelSize.small
    color: root.isHovered ? Theme.options.text : Theme.options.subtext1
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.onPressAction: root.clicked()

    Hintable {
      label: root.accessibleName
      onActivated: root.clicked()
    }
  }
}
