import Quickshell
import Quickshell.Widgets
import QtQuick

import qs.config
import qs.widgets.common

IconImage {
  id: root

  property bool enableColoriser: false
  property string color: "black"
  property string sourceColor: "white"
  property string icon
  property int size: Styles.font.pixelSize.normal

  source: Quickshell.iconPath(icon.length > 0 ? icon : "image-missing")
  width: size
  height: size
  layer.enabled: root.enableColoriser
  layer.effect: Coloriser {
    sourceColor: root.sourceColor
    colorizationColor: root.color
  }
}
