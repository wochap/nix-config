import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.widgets.common

WrapperRectangle {
  color: "transparent"
  margin: 0

  ColumnLayout {
    spacing: -Styles?.font.pixelSize.small / 2

    StyledText {
      text: Hypr.activeWindow?.class ?? ""
      font.pixelSize: Styles?.font.pixelSize.small
    }
    StyledText {
      text: Hypr.activeWindow?.title ?? ""
      font.pixelSize: Styles?.font.pixelSize.small
    }
  }
}
