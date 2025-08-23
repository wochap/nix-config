import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import qs.services
import qs.widgets.common

WrapperRectangle {
  color: "transparent"
  margin: 0
  Layout.maximumWidth: 300

  ColumnLayout {
    anchors.fill: parent
    spacing: -Styles?.font.pixelSize.small / 2

    StyledText {
      Layout.fillWidth: true

      text: Hypr.activeWindow?.class ?? ""
      font.pixelSize: Styles?.font.pixelSize.small
      elide: Text.ElideMiddle
    }
    StyledText {
      Layout.fillWidth: true

      text: Hypr.activeWindow?.title ?? ""
      font.pixelSize: Styles?.font.pixelSize.small
      elide: Text.ElideMiddle
    }
  }
}
