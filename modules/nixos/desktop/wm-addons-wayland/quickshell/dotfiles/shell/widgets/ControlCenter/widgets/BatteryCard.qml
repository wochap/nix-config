import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.ControlCenter

StyledRect {
  id: root

  readonly property int percentage: Math.round(SUpower.percentage * 100)
  readonly property bool isDischarging: SUpower.chargeState == UPowerDeviceState.Discharging
  readonly property real health: UPower.displayDevice.healthPercentage
  // legion conservation mode stops charging at 80%
  readonly property int chargeLimit: SLegionBatteryConservation.isActive ? 80 : -1
  readonly property color fillColor: root.percentage <= 15 && root.isDischarging ? Theme.options.red : Theme.options.green

  implicitHeight: content.implicitHeight + 20
  radius: Styles.radius.windowRounding
  color: Theme.options.mantle
  border {
    width: 1
    color: Theme.options.surface0
  }

  ColumnLayout {
    id: content

    anchors {
      fill: parent
      topMargin: 10
      bottomMargin: 10
      leftMargin: 12
      rightMargin: 12
    }
    spacing: 8

    RowLayout {
      spacing: 10

      StyledText {
        text: `${root.percentage}%`
        font.pixelSize: Styles.font.pixelSize.huge
        font.weight: Font.Medium
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        RowLayout {
          spacing: 3

          SystemIcon {
            enableColoriser: true
            visible: SUpower.isCharging
            icon: "ac-adapter"
            size: Styles.font.pixelSize.hugeass
            color: Theme.options.green
          }

          StyledText {
            text: {
              const rate = Math.abs(SUpower.energyRate);
              return rate > 0 ? `${SUpower.batteryLabel} · ${rate.toFixed(1)} W` : SUpower.batteryLabel;
            }
            font.pixelSize: Styles.font.pixelSize.small
            color: SUpower.isCharging ? Theme.options.green : Theme.options.text
          }
        }

        StyledText {
          text: {
            const parts = [];
            if (SUpower.isCharging && SUpower.timeToFull > 0) {
              parts.push(`Full in ${Global.formatTimeRemaining(SUpower.timeToFull)}`);
            } else if (root.isDischarging && SUpower.timeToEmpty > 0) {
              parts.push(`${Global.formatTimeRemaining(SUpower.timeToEmpty)} left`);
            }
            if (root.chargeLimit > 0) {
              parts.push(`limit ${root.chargeLimit}%`);
            }
            return parts.join(" · ");
          }
          visible: text !== ""
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }
      }

      ColumnLayout {
        spacing: 0

        StyledText {
          Layout.alignment: Qt.AlignRight
          visible: root.health > 0
          text: `Health <font color="${Theme.options.text}">${Math.round(root.health)}%</font>`
          textFormat: Text.StyledText
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }

        StyledText {
          Layout.alignment: Qt.AlignRight
          visible: SSystemInfo.batteryCycles >= 0
          text: `Cycles <font color="${Theme.options.text}">${SSystemInfo.batteryCycles}</font>`
          textFormat: Text.StyledText
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }
      }
    }

    Item {
      Layout.fillWidth: true
      implicitHeight: 6

      StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: Theme.options.surface1

        StyledRect {
          anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
          }
          width: parent.width * Math.max(0, Math.min(1, SUpower.percentage))
          radius: height / 2
          color: root.fillColor
        }
      }

      // charge limit tick
      Rectangle {
        visible: root.chargeLimit > 0
        x: parent.width * root.chargeLimit / 100 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 12
        radius: 1
        color: Theme.options.text
      }
    }
  }
}
