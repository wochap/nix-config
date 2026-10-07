import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.widgets.common
import qs.Woints

// One window preview: a 16:10 capture, workspace badge and an icon + title row.
// States: default, hovered, selected (2px ring + scale), urgent and special.
Item {
  id: tile

  required property var entry
  property real previewHeight: 140
  property bool selected: false
  property bool interactive: true
  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool urgent: tile.entry?.urgent ?? false
  readonly property bool special: tile.entry?.special ?? false
  readonly property string key: tile.entry?.key ?? ""
  readonly property real padding: 6

  signal clicked

  implicitHeight: tile.padding * 3 + tile.previewHeight + 24
  z: tile.selected ? 1 : 0
  scale: tile.selected ? 1.04 : 1

  Behavior on scale {
    animation: Styles.animations.numberAnimation.createObject(tile)
  }

  // Soft outer ring of the selected tile.
  StyledRect {
    anchors {
      fill: background
      margins: -4
    }
    radius: Styles.radius.windowRounding + 4
    color: tile.selected ? Theme.addAlpha(Theme.options.primary, 0.14) : "transparent"
  }

  StyledRect {
    id: background

    anchors.fill: parent
    radius: Styles.radius.windowRounding
    color: tile.selected ? Theme.options.surface0 : tile.hovered ? Theme.tint(Theme.options.background, Theme.options.surface0, 0.5) : Theme.options.background
    border {
      width: tile.selected ? 2 : 1
      color: {
        if (tile.selected)
          return Theme.options.primary;
        if (tile.hovered)
          return Theme.options.surface1;
        if (tile.urgent)
          return Theme.addAlpha(Theme.options.red, 0.6);
        return Theme.options.borderSecondary;
      }
    }

    Behavior on border.color {
      animation: Styles.animations.colorAnimation.createObject(tile)
    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    enabled: tile.interactive
    hoverEnabled: true
    cursorShape: tile.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: tile.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: tile.entry?.title ?? ""
    Accessible.description: tile.special ? (tile.entry?.specialName ?? "") : `Workspace ${tile.entry?.workspace ?? ""}`
    Accessible.selectable: true
    Accessible.selected: tile.selected
    Accessible.onPressAction: tile.clicked()

    Hintable {
      enabled: tile.interactive
      label: tile.entry?.title ?? ""
      onActivated: tile.clicked()
    }
  }

  ClippingRectangle {
    id: preview

    x: tile.padding
    y: tile.padding
    width: tile.width - 2 * tile.padding
    height: tile.previewHeight
    radius: Styles.radius.small
    color: Theme.options.backgroundOverlay

    Item {
      anchors.fill: parent
      opacity: tile.special ? 0.55 : 1

      // Cover the 16:10 box: scale the capture up and crop the overflow.
      ScreencopyView {
        id: capture

        readonly property real coverScale: {
          const w = capture.sourceSize.width;
          const h = capture.sourceSize.height;
          return w > 0 && h > 0 ? Math.max(preview.width / w, preview.height / h) : 1;
        }

        anchors.centerIn: parent
        width: capture.sourceSize.width > 0 ? capture.sourceSize.width * capture.coverScale : parent.width
        height: capture.sourceSize.height > 0 ? capture.sourceSize.height * capture.coverScale : parent.height
        captureSource: tile.entry?.captureSource ?? null
        live: false
        visible: capture.captureSource !== null
      }

      SystemIcon {
        anchors.centerIn: parent
        visible: !capture.hasContent
        opacity: 0.6
        icon: tile.entry?.icon ?? ""
        size: 32
      }
    }

    // Harpoon key and urgent dot share the top-left corner.
    Row {
      anchors {
        top: parent.top
        left: parent.left
        margins: 5
      }
      spacing: 4

      Keycap {
        visible: tile.key.length > 0
        text: tile.key.toUpperCase()
      }

      Rectangle {
        visible: tile.urgent
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 8
        implicitHeight: 8
        radius: 4
        color: Theme.options.red
        border {
          width: 2
          color: Theme.options.background
        }
      }
    }

    // Workspace badge.
    Rectangle {
      visible: badgeLabel.text.length > 0
      anchors {
        top: parent.top
        right: parent.right
        margins: 5
      }
      implicitWidth: Math.max(18, badgeLabel.implicitWidth + 10)
      implicitHeight: 18
      radius: 9
      color: {
        if (tile.selected)
          return Theme.options.primary;
        if (tile.urgent)
          return Theme.options.red;
        return Theme.addAlpha(Theme.options.crust, 0.85);
      }
      border {
        width: tile.special && !tile.selected ? 1 : 0
        color: Theme.options.primary
      }

      StyledText {
        id: badgeLabel

        anchors.centerIn: parent
        text: tile.entry?.workspace ?? ""
        font.pixelSize: Styles.font.pixelSize.smaller
        font.weight: Font.Bold
        color: {
          if (tile.selected || tile.urgent)
            return Theme.options.crust;
          if (tile.special)
            return Theme.options.primary;
          return Theme.options.text;
        }
      }
    }

    // Special workspace tag.
    Rectangle {
      visible: tile.special && specialLabel.text.length > 0
      anchors {
        left: parent.left
        bottom: parent.bottom
        margins: 5
      }
      width: Math.min(specialLabel.implicitWidth + 12, preview.width - 10)
      implicitHeight: 16
      radius: 8
      color: Theme.addAlpha(Theme.options.crust, 0.85)

      StyledText {
        id: specialLabel

        anchors {
          fill: parent
          leftMargin: 6
          rightMargin: 6
        }
        text: tile.entry?.specialName ?? ""
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.smaller
        color: Theme.options.primary
      }
    }
  }

  Row {
    x: tile.padding + 2
    y: preview.y + preview.height + tile.padding
    width: tile.width - 2 * (tile.padding + 2)
    height: 24
    spacing: 8

    SystemIcon {
      anchors.verticalCenter: parent.verticalCenter
      icon: tile.entry?.icon ?? ""
      size: 20
    }

    StyledText {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 28
      elide: Text.ElideRight
      font.pixelSize: Styles.font.pixelSize.small
      text: tile.entry?.title ?? ""
      color: {
        if (tile.selected || tile.hovered)
          return Theme.options.text;
        if (tile.urgent)
          return Theme.options.red;
        if (tile.special)
          return Theme.options.overlay1;
        return Theme.options.subtext0;
      }
    }
  }
}
