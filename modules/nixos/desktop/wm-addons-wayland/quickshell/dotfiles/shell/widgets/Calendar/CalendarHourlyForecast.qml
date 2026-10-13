import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

// Next 24h: icon, temperature curve and rain chance per hour, scrolls horizontally
Item {
  id: root

  readonly property var hours: SWeather.hourly
  // 6.5 columns visible, the clipped half column hints that there is more to scroll
  readonly property real columnWidth: root.width / 6.5
  readonly property real labelHeight: 14
  readonly property real iconHeight: 22
  readonly property real curveHeight: 44
  readonly property real rainHeight: 12
  readonly property real tempLabelHeight: 13
  readonly property var curveTemps: hours.map(h => h.temperature).concat(SWeather.hourlyNext ? [SWeather.hourlyNext.temperature] : [])
  readonly property real minTemp: curveTemps.length > 0 ? Math.min(...curveTemps) : 0
  readonly property real maxTemp: curveTemps.length > 0 ? Math.max(...curveTemps) : 0
  // keeps room for the temperature label above the warmest dot
  readonly property real curveTop: root.tempLabelHeight + 7
  readonly property real curveBottom: root.curveHeight - 4

  function pointY(temp) {
    const range = root.maxTemp - root.minTemp;
    if (range === 0)
      return (root.curveTop + root.curveBottom) / 2;
    return root.curveBottom - (temp - root.minTemp) / range * (root.curveBottom - root.curveTop);
  }

  function curveColor(isDay) {
    return isDay ? Theme.options.yellow : Theme.options.lavender;
  }

  implicitHeight: root.labelHeight + root.iconHeight + root.curveHeight + root.rainHeight + 6

  Flickable {
    id: flick

    anchors.fill: parent
    contentWidth: root.hours.length * root.columnWidth
    contentHeight: height
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    function clampX(x) {
      return Math.max(0, Math.min(flick.contentWidth - flick.width, x));
    }

    NumberAnimation {
      id: scrollAnim

      target: flick
      property: "contentX"
      duration: 150
      easing.type: Easing.OutCubic
    }

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: event => {
        const pixels = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y;
        if (pixels !== 0) {
          // touchpad: follow the fingers 1:1
          scrollAnim.stop();
          flick.contentX = flick.clampX(flick.contentX - pixels);
          return;
        }
        // mouse notch: glide, and chain notches from where the glide is heading
        const delta = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
        const base = scrollAnim.running ? scrollAnim.to : flick.contentX;
        scrollAnim.stop();
        scrollAnim.to = flick.clampX(base - delta / 2);
        scrollAnim.start();
      }
    }

    // night bands, contiguous night hours merge into one
    Row {
      Repeater {
        model: root.hours

        Rectangle {
          required property var modelData

          width: root.columnWidth
          height: flick.height
          color: modelData.isDay ? "transparent" : Theme.addAlpha(Theme.options.crust, 0.55)
        }
      }
    }

    // current hour, same pill as today in the daily row
    StyledRect {
      width: root.columnWidth
      height: flick.height
      radius: Styles.radius.windowRounding
      color: Theme.options.surface0
      visible: root.hours.length > 0
    }

    Canvas {
      id: curve

      y: root.labelHeight + root.iconHeight
      width: flick.contentWidth
      height: root.curveHeight

      onWidthChanged: requestPaint()

      onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const hours = root.hours;
        const pts = hours.map((h, i) => ({
              x: (i + 0.5) * root.columnWidth,
              y: root.pointY(h.temperature),
              isDay: h.isDay
            }));
        if (pts.length < 2)
          return;
        const labelXs = pts.map(p => p.x);
        const labelYs = pts.map(p => p.y);

        // left edge runs flat, right edge heads toward the next hour (clipped at the canvas edge)
        pts.unshift({
          x: 0,
          y: pts[0].y,
          isDay: pts[0].isDay
        });
        const next = SWeather.hourlyNext;
        const last = pts[pts.length - 1];
        pts.push({
          x: (hours.length + 0.5) * root.columnWidth,
          y: next ? root.pointY(next.temperature) : last.y,
          isDay: next ? next.isDay : last.isDay
        });

        const line = () => {
          ctx.beginPath();
          ctx.moveTo(pts[0].x, pts[0].y);
          for (let i = 1; i < pts.length; i++) {
            const mx = (pts[i - 1].x + pts[i].x) / 2;
            ctx.bezierCurveTo(mx, pts[i - 1].y, mx, pts[i].y, pts[i].x, pts[i].y);
          }
        };
        // yellow by day, lavender by night, blended between hours
        const paint = alpha => {
          const gradient = ctx.createLinearGradient(0, 0, width, 0);
          for (const p of pts)
            gradient.addColorStop(Math.min(1, p.x / width), Qt.alpha(root.curveColor(p.isDay), alpha));
          return gradient;
        };

        line();
        ctx.lineTo(pts[pts.length - 1].x, height);
        ctx.lineTo(pts[0].x, height);
        ctx.closePath();
        ctx.fillStyle = paint(0.16);
        ctx.fill();

        line();
        ctx.strokeStyle = paint(1);
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.stroke();

        // cut a gap in the line behind each temperature label so the text stays readable
        for (let i = 0; i < labelXs.length; i++)
          ctx.clearRect(labelXs[i] - 12, labelYs[i] - 4 - root.tempLabelHeight - 1, 24, root.tempLabelHeight + 3);
      }

      Connections {
        target: root

        function onHoursChanged() {
          curve.requestPaint();
        }

        function onColumnWidthChanged() {
          curve.requestPaint();
        }
      }

      Connections {
        target: SWeather

        function onHourlyNextChanged() {
          curve.requestPaint();
        }
      }

      Connections {
        target: Theme

        function onChanged() {
          curve.requestPaint();
        }
      }

      Component.onCompleted: requestPaint()
    }

    Row {
      Repeater {
        model: root.hours

        Item {
          id: cell

          required property var modelData
          required property int index
          readonly property bool isMidnight: modelData.hour === "00" && index > 0
          readonly property real dotY: root.labelHeight + root.iconHeight + root.pointY(modelData.temperature)

          width: root.columnWidth
          height: flick.height

          // day boundary
          Rectangle {
            visible: cell.isMidnight
            width: 1
            height: parent.height
            color: Theme.options.surface1
          }

          StyledText {
            y: 0
            width: parent.width
            height: root.labelHeight
            horizontalAlignment: Text.AlignHCenter
            text: cell.index === 0 ? "Now" : cell.isMidnight ? Qt.formatDate(cell.modelData.date, "ddd") : cell.modelData.hour
            font.pixelSize: Styles.font.pixelSize.smaller
            font.weight: cell.index === 0 || cell.isMidnight ? Font.Medium : Font.Normal
            color: cell.index === 0 ? Theme.options.text : cell.isMidnight ? Theme.options.subtext0 : Theme.options.overlay1
          }

          MaterialIcon {
            y: root.labelHeight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            icon: cell.modelData.icon
            size: Styles.font.pixelSize.large
            fill: 1
            weight: Font.Normal
            color: cell.modelData.iconColor
          }

          // temperature dot + label following the curve
          Rectangle {
            x: (parent.width - width) / 2
            y: cell.dotY - height / 2
            width: 5
            height: 5
            radius: 2.5
            color: root.curveColor(cell.modelData.isDay)
          }

          StyledText {
            y: cell.dotY - root.tempLabelHeight - 4
            width: parent.width
            height: root.tempLabelHeight
            horizontalAlignment: Text.AlignHCenter
            text: `${cell.modelData.temperature}°`
            font.pixelSize: Styles.font.pixelSize.smaller
            font.weight: cell.index === 0 ? Font.Medium : Font.Normal
          }

          // rain chance, only when it is worth a glance
          RowLayout {
            y: root.labelHeight + root.iconHeight + root.curveHeight + 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            visible: cell.modelData.precipitation >= 10

            MaterialIcon {
              icon: "water_drop"
              size: Styles.font.pixelSize.smaller
              weight: Font.Normal
              color: Theme.options.blue
            }

            StyledText {
              text: `${cell.modelData.precipitation}%`
              font.pixelSize: Styles.font.pixelSize.smaller
              color: Theme.options.subtext0
            }
          }
        }
      }
    }
  }

  // edge fades, show up only when there is more to scroll in that direction
  Rectangle {
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
    }
    width: 20
    opacity: flick.contentX > 1 ? 1 : 0
    visible: opacity > 0
    gradient: Gradient {
      orientation: Gradient.Horizontal

      GradientStop {
        position: 0
        color: Theme.options.mantle
      }

      GradientStop {
        position: 1
        color: Qt.alpha(Theme.options.mantle, 0)
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 120
      }
    }
  }

  Rectangle {
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }
    width: 20
    opacity: flick.atXEnd ? 0 : 1
    visible: opacity > 0
    gradient: Gradient {
      orientation: Gradient.Horizontal

      GradientStop {
        position: 0
        color: Qt.alpha(Theme.options.mantle, 0)
      }

      GradientStop {
        position: 1
        color: Theme.options.mantle
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 120
      }
    }
  }
}
