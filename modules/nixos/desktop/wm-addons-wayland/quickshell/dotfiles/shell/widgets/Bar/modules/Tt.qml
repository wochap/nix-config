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
          implicitWidth: chipModule.implicitWidth
          implicitHeight: chipModule.implicitHeight

          Module {
            id: chipModule

            anchors.fill: parent
            iconSystem: "appointment-soon-symbolic"
            iconSystemSize: Styles.font.pixelSize.large
            iconSize: Styles.font.pixelSize.huge
            label: `${STt.title(chip.modelData)} ${STt.elapsed(chip.modelData)}`
            paddingX: 0
            bgColor: "transparent"
            fgColor: Theme.options.green
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
