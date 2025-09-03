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
  required property SNotification notification
  required property bool isPopup

  color: Theme.addAlpha(root.isPopup ? Theme.options.backgroundOverlay : Theme.options.background, root.isPopup && Global.isBlurEnabled ? 0.65 : 1)
  radius: 8
  margin: 8
  border {
    width: 1
    color: Theme.options.border
  }

  child: RowLayout {
    id: rowLayout

    StyledText {
      Layout.fillWidth: true
      text: JSON.stringify(modelData)
      wrapMode: Text.WordWrap
    }
  }
}
