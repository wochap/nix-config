import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

RowLayout {
  // required property int index
  required property SNotification modelData

  StyledText {
    Layout.fillWidth: true
    text: JSON.stringify(modelData)
    wrapMode: Text.WordWrap
  }
}
