import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

// One chip per running tt entry. Left click stops it, middle click stops all.
// Horizontal chips show "title elapsed", vertical chips only the elapsed time.
StatusModule {
  id: root

  isVisible: STt.count > 0
  sourceComponent: Component {
    GridLayout {
      flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
      rowSpacing: 4
      columnSpacing: ConfigBar.modulesSpacing

      Repeater {
        model: STt.running

        Item {
          id: chip

          required property var modelData

          Layout.fillHeight: !root.vertical
          implicitWidth: badge.implicitWidth
          implicitHeight: badge.implicitHeight

          StatusBadge {
            id: badge

            anchors.centerIn: parent
            vertical: root.vertical
            icon: "timer"
            iconColor: Theme.options.green
            iconSize: root.iconSize
            text: root.vertical ? STt.elapsed(chip.modelData) : `${STt.title(chip.modelData)} ${STt.elapsed(chip.modelData)}`
            fontSize: root.fontSize
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
              if (event.button === Qt.MiddleButton)
                STt.stopAll();
              else
                STt.stop(chip.modelData.id);
            }
          }
        }
      }
    }
  }
}
