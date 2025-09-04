import QtQuick
import qs.config

NotificationButton {
  id: root

  materialIconSize: Styles.font.pixelSize.large
  textSize: Styles.font.pixelSize.small
  verticalPadding: root.text.length > 0 ? 4 : 2
  horizontalPadding: root.text.length > 0 ? 6 : 4
}
