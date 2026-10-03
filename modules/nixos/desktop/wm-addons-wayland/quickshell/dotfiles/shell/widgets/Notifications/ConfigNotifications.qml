pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  // toasts
  property real notificationsPopupsWidth: 380
  // distance from the bar and the screen edge
  property real notificationsPopupsMargin: 10
  // sidebar
  property real notificationsPanelPadding: 10
  property real notificationsPanelWidth: notificationsPopupsWidth + notificationsPanelPadding * 2
  property real notificationsSpacing: 8
  // card
  property real notificationPaddingTop: 9
  property real notificationPaddingRight: 10
  property real notificationPaddingBottom: 14
  property real notificationPaddingLeft: 12
  property real notificationSpacing: 6
  property real notificationHeaderHeight: 18
  property real notificationThumbSize: 56
  property real notificationHeaderIconSize: 15
  property real notificationButtonSize: 22
  property real notificationTimeoutBarHeight: 2
  property real notificationExitDistance: 24
}
