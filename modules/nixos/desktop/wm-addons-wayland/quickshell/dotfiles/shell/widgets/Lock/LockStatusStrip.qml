pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Lock

// status rail, bottom-left of the focused output, see design/project/LockStatusStrip.dc.html
// No notifications pill, the main shell owns the notification server.
StyledRect {
  id: root

  property bool isMediaOpen: false
  readonly property var player: SMpris.player
  readonly property bool hasMedia: root.player !== null && (root.player.isPlaying || root.player.playbackState === MprisPlaybackState.Paused)
  readonly property real batteryPercent: Math.round(SUpower.percentage * 100)
  readonly property bool isBatteryLow: !SUpower.isPluggedIn && root.batteryPercent <= 15
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property int bluetoothConnected: Bluetooth.devices.values.filter(d => d.connected).length
  readonly property bool isWeatherFresh: SWeather.current !== null && Date.now() - SWeather.fetchedAt < 60 * 60 * 1000

  signal mediaRequested

  function batteryIcon() {
    const percent = root.batteryPercent;
    if (SUpower.isCharging || SUpower.isFullyCharged) {
      if (SUpower.isFullyCharged || percent >= 95) {
        return "battery_charging_full";
      }
      const steps = [90, 80, 60, 50, 30, 20];
      return `battery_charging_${steps.find(s => percent >= s) ?? 20}`;
    }
    if (root.isBatteryLow) {
      return "battery_alert";
    }
    if (percent >= 95) {
      return "battery_full";
    }
    return `battery_${Math.max(0, Math.min(6, Math.floor(percent / 100 * 7)))}_bar`;
  }

  function batteryLabel() {
    if (SUpower.isFullyCharged) {
      return "full";
    }
    if (SUpower.isCharging) {
      return "charging";
    }
    return SUpower.timeToEmpty > 0 ? `${Global.formatTimeRemaining(SUpower.timeToEmpty)} left` : "";
  }

  implicitWidth: row.implicitWidth + 12
  implicitHeight: ConfigLock.railHeight
  radius: ConfigLock.radius
  color: Theme.options.mantle
  border.width: 1
  border.color: Theme.options.surface0

  component Pill: RowLayout {
    id: pill

    required property string icon
    property color iconColor: Theme.options.text
    property real iconFill: 0
    property real iconRotation: 0
    property string value: ""
    property color valueColor: Theme.options.text
    property string qualifier: ""

    Layout.preferredHeight: ConfigLock.pillHeight
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    spacing: 6

    MaterialIcon {
      icon: pill.icon
      size: 16
      fill: pill.iconFill
      weight: Font.Normal
      color: pill.iconColor
      rotation: pill.iconRotation
    }

    StyledText {
      visible: text !== ""
      text: pill.value
      color: pill.valueColor
      font.pixelSize: Styles.font.pixelSize.small
    }

    StyledText {
      visible: text !== ""
      text: pill.qualifier
      color: ConfigLock.subtext
      font.pixelSize: Styles.font.pixelSize.small
    }
  }

  component PillButton: StyledRect {
    id: pillButton

    required property string icon
    required property string label
    property bool canUse: true

    signal activated

    implicitWidth: 24
    implicitHeight: 24
    radius: 12
    opacity: pillButton.canUse ? 1 : ConfigLock.disabledOpacity
    Accessible.role: Accessible.Button
    Accessible.name: pillButton.label
    Accessible.onPressAction: {
      if (pillButton.canUse) {
        pillButton.activated();
      }
    }
    color: buttonMouseArea.containsMouse ? Theme.options.surface0 : "transparent"

    MaterialIcon {
      anchors.centerIn: parent
      icon: pillButton.icon
      size: 16
      fill: 1
      weight: Font.Normal
      color: buttonMouseArea.containsMouse ? Theme.options.text : ConfigLock.subtext
    }

    MouseArea {
      id: buttonMouseArea

      anchors.fill: parent
      enabled: pillButton.canUse
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pillButton.activated()
    }
  }

  RowLayout {
    id: row

    anchors {
      left: parent.left
      leftMargin: 6
      verticalCenter: parent.verticalCenter
    }
    spacing: 4

    // battery glyphs are rotated 90°, same as the bar
    Pill {
      visible: SUpower.available
      icon: root.batteryIcon()
      iconRotation: 90
      iconColor: SUpower.isCharging ? Theme.options.green : root.isBatteryLow ? Theme.options.red : Theme.options.text
      value: `${root.batteryPercent}%`
      valueColor: root.isBatteryLow ? Theme.options.red : Theme.options.text
      qualifier: root.batteryLabel()
    }

    Pill {
      readonly property bool isWifi: SNetwork.wifi?.connected ?? false
      readonly property bool isWired: SNetwork.wired?.connected ?? false

      icon: isWifi ? "wifi" : isWired ? "lan" : "wifi_off"
      iconColor: isWifi || isWired ? Theme.options.text : ConfigLock.overlay
      qualifier: isWifi ? (SNetwork.wifi.ssid || "wifi") : isWired ? (SNetwork.wired.interface || "wired") : "offline"
    }

    Pill {
      readonly property bool isOn: root.adapter?.enabled ?? false

      visible: root.adapter !== null
      icon: !isOn ? "bluetooth_disabled" : root.bluetoothConnected > 0 ? "bluetooth_connected" : "bluetooth"
      iconColor: isOn ? Theme.options.text : ConfigLock.overlay
      qualifier: !isOn ? "off" : root.bluetoothConnected > 0 ? `${root.bluetoothConnected} connected` : "on"
    }

    Pill {
      visible: root.isWeatherFresh
      icon: SWeather.current?.icon ?? "cloud"
      iconFill: 1
      iconColor: SWeather.current?.iconColor ?? Theme.options.text
      value: `${SWeather.current?.temperature ?? ""}°`
      qualifier: SWeather.city
    }

    // last, so showing or hiding it never moves the others
    StyledRect {
      id: mediaPill

      readonly property bool isHovered: mediaMouseArea.containsMouse

      Layout.preferredHeight: ConfigLock.pillHeight
      Layout.preferredWidth: root.hasMedia ? mediaRow.implicitWidth + 6 : 0
      visible: Layout.preferredWidth > 0
      // clip only while the width animates, else it cuts the focus ring
      clip: width < mediaRow.implicitWidth + 6
      opacity: root.hasMedia ? 1 : 0
      radius: ConfigLock.pillHeight / 2
      activeFocusOnTab: root.hasMedia
      Accessible.role: Accessible.Button
      Accessible.name: `Media: ${root.player?.trackTitle || "Unknown title"}`
      Accessible.onPressAction: root.mediaRequested()
      color: root.isMediaOpen ? Theme.addAlpha(String(ConfigLock.ink), ConfigLock.openTint) : mediaPill.isHovered ? Theme.options.surface0 : "transparent"
      border.width: root.isMediaOpen ? 1 : 0
      border.color: Theme.addAlpha(String(ConfigLock.ink), ConfigLock.openLine)

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.mediaRequested();
          event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
          root.player?.togglePlaying();
          event.accepted = true;
        }
      }

      Behavior on Layout.preferredWidth {
        NumberAnimation {
          duration: root.hasMedia ? Styles.animation.duration : Styles.animation.exitDuration
          easing.type: root.hasMedia ? Styles.animation.easingType : Styles.animation.exitEasingType
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: root.hasMedia ? Styles.animation.duration : Styles.animation.exitDuration
          easing.type: root.hasMedia ? Styles.animation.easingType : Styles.animation.exitEasingType
        }
      }

      // focus ring: 2px mantle gap + 2px ink
      StyledRect {
        anchors {
          fill: parent
          margins: -4
        }
        visible: mediaPill.activeFocus
        radius: height / 2
        border.width: 2
        border.color: ConfigLock.ink
      }

      MouseArea {
        id: mediaMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.mediaRequested()
      }

      RowLayout {
        id: mediaRow

        anchors {
          left: parent.left
          leftMargin: 4
          verticalCenter: parent.verticalCenter
        }
        spacing: 6

        ClippingRectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: 20
          radius: Styles.radius.small
          color: Theme.options.surface0

          MaterialIcon {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            icon: "album"
            size: 14
            weight: Font.Normal
            color: ConfigLock.overlay
          }

          Image {
            id: cover

            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: 40
            sourceSize.height: 40
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }
        }

        StyledText {
          Layout.maximumWidth: 140
          text: root.player?.trackTitle || "Unknown title"
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.small
        }

        StyledText {
          Layout.maximumWidth: 100
          visible: text !== ""
          text: root.player?.trackArtist ?? ""
          elide: Text.ElideRight
          color: ConfigLock.subtext
          font.pixelSize: Styles.font.pixelSize.small
        }

        PillButton {
          icon: root.player?.isPlaying ? "pause" : "play_arrow"
          label: root.player?.isPlaying ? "Pause" : "Play"
          canUse: root.player?.canTogglePlaying ?? false
          onActivated: root.player.togglePlaying()
        }

        PillButton {
          Layout.leftMargin: -4
          icon: "skip_next"
          label: "Next track"
          canUse: root.player?.canGoNext ?? false
          onActivated: root.player.next()
        }
      }
    }
  }
}
