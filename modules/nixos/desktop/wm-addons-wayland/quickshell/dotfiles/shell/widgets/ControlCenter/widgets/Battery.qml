import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

RowLayout {
  spacing: 4

  SystemIcon {
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignVCenter
    icon: SUpower.batteryIcon
    size: Styles.font.pixelSize.hugeass
    enableColoriser: true
    color: Theme.options.text
  }

  StyledText {
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    text: `${Math.round(SUpower.percentage * 100)}%`
    font.pixelSize: Styles.font.pixelSize.small
  }

  StyledText {
    property bool isDischarging: SUpower.batteryLabel === "Discharging"
    property bool isFullCharged: SUpower.batteryLabel === "Full charged"

    Layout.alignment: Qt.AlignVCenter
    text: `${SUpower.batteryLabel}${isFullCharged ? "" : ` · ${Global.formatTimeRemaining(isDischarging ? SUpower.timeToEmpty : SUpower.timeToFull)} left`}`
    font.pixelSize: Styles.font.pixelSize.small
  }
}
