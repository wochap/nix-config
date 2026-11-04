import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

// One chip per running tt entry. Left click stops it, middle click stops all.
Loader {
  id: root

  property bool isVisible: STt.count > 0

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    RowLayout {
      spacing: ConfigBar.modulesSpacing

      Repeater {
        model: STt.running

        Item {
          id: chip

          required property var modelData

          Layout.fillHeight: true
          implicitWidth: chipRow.implicitWidth
          implicitHeight: chipRow.implicitHeight

          RowLayout {
            id: chipRow

            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
              icon: "timer"
              size: ConfigBar.statusIconSize
              weight: Font.Normal
              color: Theme.options.green
            }

            StyledText {
              text: `${STt.title(chip.modelData)} ${STt.elapsed(chip.modelData)}`
              font.pixelSize: ConfigBar.statusFontSize
              font.weight: 600
              color: Theme.options.subtext1
            }
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
