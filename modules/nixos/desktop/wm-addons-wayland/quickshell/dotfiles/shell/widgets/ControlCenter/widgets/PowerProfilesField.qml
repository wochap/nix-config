pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

// segmented control for power-profiles-daemon
StyledRect {
  id: root

  readonly property var labels: ({
      "power-saver": "Saver",
      balanced: "Balanced",
      performance: "Perform."
    })
  readonly property var order: ["power-saver", "balanced", "performance"]
  readonly property var icons: ({
      "power-saver": "eco",
      balanced: "balance",
      performance: "rocket_launch"
    })

  implicitHeight: 32
  radius: height / 2
  color: Theme.options.mantle
  border {
    width: 1
    color: Theme.options.surface0
  }

  RowLayout {
    anchors {
      fill: parent
      margins: 2
    }
    spacing: 2

    Repeater {
      // saver → balanced → performance, regardless of the daemon order
      model: [...SPowerProfiles.list].sort((a, b) => root.order.indexOf(a.profile) - root.order.indexOf(b.profile))

      delegate: StyledRect {
        id: segment

        required property var modelData
        readonly property bool isSelected: modelData.profile === SPowerProfiles.active

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        radius: height / 2
        color: segment.isSelected ? Theme.addAlpha(Theme.options.primary, Styles.tint.hover) : mouseArea.containsMouse ? Theme.options.surface0 : "transparent"
        border {
          width: segment.isSelected ? 1 : 0
          color: Theme.addAlpha(Theme.options.primary, 0.5)
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: 5

          MaterialIcon {
            icon: root.icons[segment.modelData.profile] ?? segment.modelData.icon
            size: 15
            weight: Font.Normal
            color: label.color
          }

          StyledText {
            id: label

            text: root.labels[segment.modelData.profile] ?? segment.modelData.profile
            font.pixelSize: Styles.font.pixelSize.small
            font.weight: segment.isSelected ? Font.Medium : Font.Normal
            color: segment.isSelected ? Theme.options.primary : mouseArea.containsMouse ? Theme.options.text : Theme.options.subtext0
          }
        }

        MouseArea {
          id: mouseArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (!segment.isSelected) {
              SPowerProfiles.set(segment.modelData.profile);
            }
          }
        }
      }
    }
  }
}
