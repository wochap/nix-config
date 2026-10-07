import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.widgets.common
import qs.Woints

// 44px device row: tile, name + status, action button
Item {
  id: root

  required property BluetoothDevice device
  property bool isFocused: false
  property bool isConnecting: false
  property bool isFailed: false
  property color ink: Theme.options.primary
  property color subtext: Theme.options.subtext0
  property color overlay: Theme.options.overlay2
  readonly property bool isConnected: root.device?.connected ?? false
  readonly property bool isPaired: (root.device?.paired ?? false) || (root.device?.bonded ?? false)
  readonly property bool isHovered: mouseArea.containsMouse
  readonly property string action: root.isConnecting ? "Cancel" : root.isFailed ? "Retry" : root.isConnected ? "Disconnect" : root.isPaired ? "Connect" : "Pair"
  // Disconnect stays neutral, the others light up on the focused row
  readonly property bool isActionHighlighted: root.isFocused && !root.isConnected && !root.isConnecting

  signal activated
  signal clicked

  function iconFor(name) {
    const icons = [["keyboard", "keyboard"], ["mouse", "mouse"], ["headset", "headset_mic"], ["headphone", "headphones"], ["speaker", "speaker"], ["audio", "speaker"], ["phone", "smartphone"], ["computer", "computer"], ["gaming", "sports_esports"], ["joystick", "sports_esports"], ["tablet", "tablet"], ["watch", "watch"], ["camera", "photo_camera"], ["printer", "print"]];
    return icons.find(([match, _]) => (name ?? "").includes(match))?.[1] ?? "bluetooth";
  }

  function statusText() {
    if (root.isConnecting) {
      return "Connecting…";
    }
    if (root.isFailed) {
      return "Couldn’t connect · put it in pairing mode";
    }
    if (root.isConnected) {
      return root.device.batteryAvailable ? `Connected · ${Math.round(root.device.battery * 100)}%` : "Connected";
    }
    return root.isPaired ? "Paired" : "Available · not paired";
  }

  implicitHeight: 44

  StyledRect {
    anchors.fill: parent
    radius: 6
    color: root.isFocused || root.isHovered ? Theme.options.surface0 : "transparent"
    border.width: root.isFocused ? 1 : 0
    border.color: root.ink
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
    Accessible.role: Accessible.ListItem
    Accessible.name: root.device?.name || root.device?.address || ""
    Accessible.description: root.statusText()
    Accessible.onPressAction: root.clicked()

    Hintable {
      label: root.device?.name || root.device?.address || ""
      onActivated: root.clicked()
    }
  }

  RowLayout {
    anchors {
      fill: parent
      leftMargin: 6
      rightMargin: 8
    }
    spacing: 10

    StyledRect {
      Layout.preferredWidth: 28
      Layout.preferredHeight: 28
      radius: 6
      color: root.isConnected ? Theme.addAlpha(String(root.ink), 0.16) : root.isFocused ? Theme.options.surface1 : Theme.options.surface0

      MaterialIcon {
        anchors.centerIn: parent
        icon: root.iconFor(root.device?.icon)
        size: 16
        weight: Font.Normal
        color: root.isConnected ? root.ink : root.isFocused ? Theme.options.text : root.subtext
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0

      StyledText {
        Layout.fillWidth: true
        text: root.device?.name || root.device?.address || ""
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: Font.Medium
      }

      StyledText {
        Layout.fillWidth: true
        text: root.statusText()
        elide: Text.ElideRight
        color: root.isFailed ? Theme.options.red : root.isPaired || root.isConnected ? root.subtext : root.overlay
        font.pixelSize: Styles.font.pixelSize.smaller
      }
    }

    StyledRect {
      id: actionButton

      readonly property color tint: root.isFailed && root.isFocused ? Theme.options.red : root.isActionHighlighted ? root.ink : root.subtext

      Layout.preferredHeight: 24
      implicitWidth: actionRow.implicitWidth + 16
      radius: 6
      color: actionMouseArea.containsMouse ? Theme.options.surface1 : "transparent"
      border.width: 1
      border.color: (root.isFailed && root.isFocused) || root.isActionHighlighted ? tint : Theme.options.surface1

      RowLayout {
        id: actionRow

        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
          visible: root.isConnecting
          icon: "progress_activity"
          size: 12
          weight: Font.Bold
          color: root.ink

          RotationAnimation on rotation {
            running: root.isConnecting
            from: 0
            to: 360
            duration: 800
            loops: Animation.Infinite
          }
        }

        StyledText {
          text: root.action
          color: actionButton.tint
          font.pixelSize: Styles.font.pixelSize.small
        }
      }

      MouseArea {
        id: actionMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
        Accessible.role: Accessible.Button
        Accessible.name: `${root.action} ${root.device?.name || root.device?.address || ""}`
        Accessible.onPressAction: root.activated()

        Hintable {
          label: `${root.action} ${root.device?.name || root.device?.address || ""}`
          onActivated: root.activated()
        }
      }
    }
  }
}
