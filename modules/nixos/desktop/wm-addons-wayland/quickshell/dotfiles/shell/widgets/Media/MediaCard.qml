pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets.common

// now playing card shared by ControlCenter and the lock screen, see design/project/MediaCard.dc.html
// `panel` adds the lock panel chrome: header, volume row, key hints and keys.
FocusScope {
  id: root

  property bool panel: false
  // focus ring color of the play button in panel mode
  property color ink: Theme.options.primary
  readonly property var player: SMpris.player
  readonly property real progress: root.player && root.player.length > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0

  signal closeRequested

  function changeVolume(delta) {
    if (root.player?.volumeSupported) {
      root.player.volume = Math.max(0, Math.min(1, root.player.volume + delta));
    }
  }

  implicitWidth: root.panel ? 360 : 356
  implicitHeight: root.panel ? panelColumn.implicitHeight + 24 : card.implicitHeight

  Keys.onPressed: event => {
    if (!root.panel) {
      return;
    }
    if (event.key === Qt.Key_Escape) {
      root.closeRequested();
    } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.player?.togglePlaying();
    } else if (event.key === Qt.Key_Left) {
      root.player?.previous();
    } else if (event.key === Qt.Key_Right) {
      root.player?.next();
    } else if (event.key === Qt.Key_Up) {
      root.changeVolume(0.05);
    } else if (event.key === Qt.Key_Down) {
      root.changeVolume(-0.05);
    } else {
      return;
    }
    event.accepted = true;
  }

  component TransportButton: Item {
    id: button

    required property string icon
    required property string label
    property bool isPrimary: false
    property bool canUse: true
    property bool hasFocusRing: false

    signal activated

    implicitWidth: button.isPrimary ? 28 : 26
    implicitHeight: implicitWidth
    opacity: button.canUse ? 1 : Styles.tint.ring
    Accessible.role: Accessible.Button
    Accessible.name: button.label
    Accessible.onPressAction: {
      if (button.canUse) {
        button.activated();
      }
    }

    // focus ring: 2px mantle gap + 2px ink
    StyledRect {
      anchors {
        fill: parent
        margins: -4
      }
      visible: button.hasFocusRing
      radius: width / 2
      border.width: 2
      border.color: root.ink
    }

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
      color: button.isPrimary ? Theme.options.crust : Theme.options.subtext0
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

  StyledRectangularShadow {
    visible: root.panel
    target: panelBackground
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: panelBackground

    anchors.fill: parent
    visible: root.panel
    radius: Styles.radius.windowRounding
    color: Theme.options.mantle
    border.width: 1
    border.color: Theme.options.surface0
  }

  ColumnLayout {
    id: panelColumn

    anchors {
      fill: parent
      margins: root.panel ? 12 : 0
    }
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      Layout.leftMargin: 2
      Layout.rightMargin: 2
      visible: root.panel

      StyledText {
        Layout.fillWidth: true
        text: "NOW PLAYING"
        color: Theme.options.overlay2
        font.pixelSize: Styles.font.pixelSize.smaller
        font.letterSpacing: Styles.font.pixelSize.smaller * 0.08
      }

      StyledText {
        text: root.player?.identity ?? ""
        color: Theme.options.subtext0
        font.pixelSize: Styles.font.pixelSize.smaller
      }
    }

    StyledRect {
      id: card

      Layout.fillWidth: true
      implicitHeight: content.implicitHeight + 20
      radius: Styles.radius.windowRounding
      color: Theme.options.mantle
      border {
        width: 1
        color: Theme.options.surface0
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
              color: Theme.options.overlay2
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
              label: "Previous track"
              canUse: root.player?.canGoPrevious ?? false
              onActivated: root.player.previous()
            }

            TransportButton {
              icon: root.player?.isPlaying ? "pause" : "play_arrow"
              label: root.player?.isPlaying ? "Pause" : "Play"
              isPrimary: true
              hasFocusRing: root.panel && root.activeFocus
              canUse: root.player?.canTogglePlaying ?? false
              onActivated: root.player.togglePlaying()
            }

            TransportButton {
              icon: "skip_next"
              label: "Next track"
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
            color: Theme.options.overlay2
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
            color: Theme.options.overlay2
          }
        }
      }
    }

    // ControlCenter slider row on the player volume
    RowLayout {
      Layout.fillWidth: true
      visible: root.panel && (root.player?.volumeSupported ?? false)
      spacing: 8

      StyledRect {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: width / 2
        color: Theme.options.surface0

        MaterialIcon {
          anchors.centerIn: parent
          icon: (root.player?.volume ?? 0) === 0 ? "volume_off" : "volume_up"
          size: 16
          weight: Font.Normal
          color: Theme.options.subtext0
        }
      }

      CustomSlider {
        id: volumeSlider

        Layout.fillWidth: true
        minimum: 0
        maximum: 100
        step: 5
        value: Math.round((root.player?.volume ?? 0) * 100)
        ringColor: Theme.options.mantle
        onSliderValueChanged: newValue => {
          if (root.player) {
            root.player.volume = newValue / 100;
          }
        }
      }

      StyledText {
        Layout.preferredWidth: 44
        horizontalAlignment: Text.AlignRight
        text: `${volumeSlider.displayValue}%`
        font.pixelSize: Styles.font.pixelSize.small
        font.features: {
          "tnum": 1
        }
      }
    }

    StyledRect {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      visible: root.panel
      color: Theme.options.surface0
    }

    KeyHints {
      Layout.fillWidth: true
      Layout.leftMargin: 2
      Layout.rightMargin: 2
      Layout.topMargin: -2
      visible: root.panel
      hints: [
        {
          key: "Space",
          text: "play/pause"
        },
        {
          key: "← →",
          text: "prev/next"
        },
        {
          key: "↑ ↓",
          text: "volume"
        },
        {
          key: "Esc",
          text: "close"
        }
      ]
    }
  }
}
