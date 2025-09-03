import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

WrapperRectangle {
  id: root

  required property int index
  required property SNotification modelData
  required property bool isPopup

  color: "transparent"
  child: Notification {
    isPopup: root.isPopup
    notification: root.modelData
  }
}
