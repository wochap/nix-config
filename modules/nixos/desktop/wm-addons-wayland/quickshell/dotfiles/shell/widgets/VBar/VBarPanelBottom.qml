import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.VBar.config
import qs.widgets.VBar.modules

ColumnLayout {
  id: root

  required property bool isFocused

  spacing: ConfigVBar.modulesSpacing

  VStatusIcons {
    Layout.alignment: Qt.AlignHCenter
    isFocused: root.isFocused
  }

  VSysTray {
    Layout.alignment: Qt.AlignHCenter
  }

  VControl {
    Layout.alignment: Qt.AlignHCenter
  }

  VClock {
    Layout.alignment: Qt.AlignHCenter
  }
}
