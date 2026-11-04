import QtQuick
import QtQuick.Layouts
import qs.widgets.Bar.config
import qs.widgets.VBar.config

// Base for bar status modules, shared by the horizontal bar and the vertical
// bar (`vertical: true`). Content is only loaded while `isVisible`; sizes and
// layout defaults follow the bar orientation.
Loader {
  id: root

  property bool vertical: false
  property bool isVisible: false
  readonly property int iconSize: root.vertical ? ConfigVBar.statusIconSize : ConfigBar.statusIconSize
  readonly property int fontSize: root.vertical ? ConfigVBar.statusFontSize : ConfigBar.statusFontSize

  Layout.fillHeight: !root.vertical
  Layout.alignment: root.vertical ? Qt.AlignHCenter : 0
  active: root.isVisible
  visible: root.isVisible
}
