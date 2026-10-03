import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets.common

StyledRect {
  id: root

  readonly property var player: SMpris.player
  readonly property real progress: root.player && root.player.length > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0

  implicitHeight: content.implicitHeight + 20
  radius: Styles.radius.windowRounding
  color: Theme.options.mantle
  border {
    width: 1
    color: Theme.options.surface0
  }

  component TransportButton: Item {
    id: button

    required property string icon
    property bool isPrimary: false
    property bool canUse: true

    signal activated

    implicitWidth: button.isPrimary ? 28 : 26
    implicitHeight: implicitWidth
    opacity: button.canUse ? 1 : Styles.tint.ring

    StyledRect {
      anchors.fill: parent
      radius: width / 2
      color: button.isPrimary ? (mouseArea.containsMouse ? Theme.options.lavender : Theme.options.primary) : mouseArea.containsMouse ? Theme.options.surface0 : "transparent"
    }

    MaterialIcon {
      anchors.centerIn: parent
      icon: button.icon
      size: 18
      fill: button.isPrimary ? 1 : 0
      weight: Font.Normal
      color: button.isPrimary ? Theme.options.crust : Theme.options.subtext1
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      enabled: button.canUse
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.activated()
    }
  }

  ColumnLayout {
    id: content

    anchors {
      fill: parent
      margins: 10
    }
    spacing: 8

    RowLayout {
      spacing: 10

      ClippingRectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: Styles.radius.small
        color: Theme.options.surface0

        MaterialIcon {
          anchors.centerIn: parent
          visible: art.status !== Image.Ready
          icon: "album"
          size: 20
          weight: Font.Normal
          color: Theme.options.overlay1
        }

        Image {
          id: art

          anchors.fill: parent
          source: root.player?.trackArtUrl ?? ""
          sourceSize.width: 80
          sourceSize.height: 80
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 0

        StyledText {
          Layout.fillWidth: true
          text: root.player?.trackTitle || "Unknown title"
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.small
          font.weight: Font.Medium
        }

        StyledText {
          Layout.fillWidth: true
          text: [root.player?.trackArtist, root.player?.identity].filter(Boolean).join(" · ")
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }
      }

      RowLayout {
        spacing: 2

        TransportButton {
          icon: "skip_previous"
          canUse: root.player?.canGoPrevious ?? false
          onActivated: root.player.previous()
        }

        TransportButton {
          icon: root.player?.isPlaying ? "pause" : "play_arrow"
          isPrimary: true
          canUse: root.player?.canTogglePlaying ?? false
          onActivated: root.player.togglePlaying()
        }

        TransportButton {
          icon: "skip_next"
          canUse: root.player?.canGoNext ?? false
          onActivated: root.player.next()
        }
      }
    }

    RowLayout {
      visible: root.player?.lengthSupported ?? false
      spacing: 8

      StyledText {
        text: SMpris.formatTime(root.player?.position)
        font.pixelSize: Styles.font.pixelSize.smaller
        color: Theme.options.overlay1
      }

      StyledRect {
        Layout.fillWidth: true
        implicitHeight: 3
        radius: height / 2
        color: Theme.options.surface1

        StyledRect {
          anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
          }
          width: parent.width * root.progress
          radius: height / 2
          color: Theme.options.primary
        }
      }

      StyledText {
        text: SMpris.formatTime(root.player?.length)
        font.pixelSize: Styles.font.pixelSize.smaller
        color: Theme.options.overlay1
      }
    }
  }
}
