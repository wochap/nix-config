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
  property string iconFallback: "image-missing"

  source: Quickshell.iconPath(icon.length > 0 ? icon : iconFallback, iconFallback)
  implicitSize: size
  layer.enabled: root.enableColoriser
  layer.effect: Coloriser {
    sourceColor: root.sourceColor
    colorizationColor: root.color
  }

  Canvas {
    id: canvas

    property int retryCount

    implicitWidth: 32
    implicitHeight: 32
    visible: false
    onPaint: {
      if (!root.layer.enabled)
        return;

      const ctx = getContext("2d");
      ctx.reset();
      ctx.drawImage(root.backer, 0, 0, width, height);

      const colors = {} as Object;
      const data = ctx.getImageData(0, 0, width, height).data;

      for (let i = 0; i < data.length; i += 4) {
        if (data[i + 3] === 0)
          continue;

        const c = `${data[i]},${data[i + 1]},${data[i + 2]}`;
        if (colors.hasOwnProperty(c))
          colors[c]++;
        else
          colors[c] = 1;
      }

      // Canvas is empty, try again next frame
      if (retryCount < 5 && !Object.keys(colors).length) {
        retryCount++;
        Qt.callLater(() => requestPaint());
        return;
      }

      let max = 0;
      let maxColor = "0,0,0";
      for (const [color, occurences] of Object.entries(colors)) {
        if (occurences > max) {
          max = occurences;
          maxColor = color;
        }
      }

      const [r, g, b] = maxColor.split(",");
      root.sourceColor = Qt.rgba(r / 255, g / 255, b / 255, 1);
      retryCount = 0;
    }
  }
}
