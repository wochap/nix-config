pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real notificationsPopupsWidth: 360
  property real notificationsPanelWidth: 360
  property real notificationsPanelPaddingY: 8
  property real notificationsPanelPaddingX: 8
  property real notificationsSpacing: 8
  property bool isBlurEnabled: Global.isBlurEnabled
}
