pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real notificationsPopupsWidth: 320
  property real notificationsPanelWidth: notificationsPopupsWidth + notificationsPanelPaddingX * 2
  property real notificationsPanelPaddingY: 8
  property real notificationsPanelPaddingX: 8
  property real notificationsSpacing: 8
  property real notificationPadding: 6
  property bool isBlurEnabled: Global.isBlurEnabled
}
