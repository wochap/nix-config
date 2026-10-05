import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// 16px checkbox, the label is part of the hit target, Space toggles
FocusScope {
  id: root

  required property string label
  property bool checked: false

  // the owner flips `checked`, keeps it a plain binding
  signal toggled

  function toggle() {
    root.toggled();
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1 : ConfigAuth.disabledOpacity

  Keys.onSpacePressed: root.toggle()

  RowLayout {
    id: row

    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    spacing: 8

    Item {
      Layout.alignment: Qt.AlignTop
      Layout.topMargin: 2
      implicitWidth: ConfigAuth.checkboxSize
      implicitHeight: ConfigAuth.checkboxSize

      StyledRect {
        anchors {
          fill: parent
          margins: -4
        }
        visible: root.activeFocus
        radius: ConfigAuth.smallRadius + 4
        border.width: 2
        border.color: ConfigAuth.ink
      }

      StyledRect {
        anchors.fill: parent
        radius: ConfigAuth.smallRadius
        color: root.checked ? ConfigAuth.ink : "transparent"
        border.width: 1
        border.color: root.checked ? ConfigAuth.ink : ConfigAuth.fieldBorder

        MaterialIcon {
          anchors.centerIn: parent
          visible: root.checked
          icon: "check"
          size: 14
          weight: Font.Bold
          color: ConfigAuth.onInk
        }
      }
    }

    StyledText {
      Layout.fillWidth: true
      text: root.label
      wrapMode: Text.Wrap
      font.pixelSize: ConfigAuth.bodySize
      lineHeight: 20
      lineHeightMode: Text.FixedHeight
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggle()
  }
}
