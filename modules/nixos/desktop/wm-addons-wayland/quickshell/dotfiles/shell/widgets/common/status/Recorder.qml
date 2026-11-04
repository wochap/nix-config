import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

// Horizontal: record icon. Vertical: red pill with a pulsing dot.
StatusModule {
  id: root

  property bool isRecording: SRecorder.isRecording

  isVisible: root.isRecording
  sourceComponent: root.vertical ? pillComponent : iconComponent

  Component {
    id: iconComponent

    MaterialIcon {
      icon: "screen_record"
      size: Styles.font.pixelSize.huge
      color: Theme.options.red
    }
  }

  Component {
    id: pillComponent

    Rectangle {
      implicitWidth: 36
      implicitHeight: 22
      radius: 11
      color: Theme.addAlpha(Theme.options.red, 0.18)

      RowLayout {
        anchors.centerIn: parent
        spacing: 3

        Rectangle {
          width: 7
          height: 7
          radius: 3.5
          color: Theme.options.red

          SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
          }
        }
      }
    }
  }
}
