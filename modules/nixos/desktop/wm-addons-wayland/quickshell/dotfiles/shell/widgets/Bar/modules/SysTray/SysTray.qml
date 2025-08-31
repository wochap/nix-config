import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

RowLayout {
  id: gridLayout

  spacing: 6

  Repeater {
    model: SystemTray.items

    SysTrayItem {
      item: modelData
      size: Styles.font.pixelSize.small
    }
  }
}
