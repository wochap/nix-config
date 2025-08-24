import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

import "Utils.js" as Utils

WrapperRectangle {
  property bool isVisible: Hypr.activeWindow ? true : false

  Layout.maximumWidth: 300 + 28

  color: "transparent"
  margin: 0
  visible: isVisible

  RowLayout {
    anchors.fill: parent

    spacing: (ConfigBar.modulesSpacing / 2) - 1

    SystemIcon {
      Layout.fillHeight: true

      icon: Utils.mapAppId(Hypr.activeWindow?.class ?? "")
      size: ConfigBar.clientIcon
    }

    ColumnLayout {
      Layout.fillHeight: true

      spacing: 0

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
}
