pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.widgets.common
import qs.widgets.Bluetooth

// BlueZ device list driven by the keyboard alone, see design/project/BluetoothPanel.dc.html
// Pairing devices that ask for a passkey needs an agent, which Quickshell doesn't provide.
FocusScope {
  id: root

  property color ink: Theme.options.primary
  property color subtext: Theme.options.subtext0
  property color overlay: Theme.options.overlay2
  property color fieldBorder: Theme.options.overlay0
  property int scanDuration: 30000
  property int connectTimeout: 15000

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property bool isOn: root.adapter?.enabled ?? false
  readonly property bool isScanning: root.adapter?.discovering ?? false
  readonly property var devices: root.adapter?.devices.values ?? []
  // sorted by name, BlueZ has no last-used time
  readonly property var connectedDevices: root.sorted(root.devices.filter(d => d.connected))
  readonly property var pairedDevices: root.sorted(root.devices.filter(d => !d.connected && (d.paired || d.bonded)))
  // unnamed devices are mostly beacons, skip them
  readonly property var availableDevices: root.sorted(root.devices.filter(d => !d.connected && !d.paired && !d.bonded && d.deviceName !== ""))
  readonly property var sections: [
    {
      label: "CONNECTED",
      devices: root.connectedDevices
    },
    {
      label: "PAIRED",
      devices: root.pairedDevices
    },
    {
      label: "AVAILABLE",
      devices: root.availableDevices
    }
  ].filter(s => s.devices.length > 0)
  readonly property var orderedDevices: root.connectedDevices.concat(root.pairedDevices, root.availableDevices)
  property string focusedAddress: ""
  readonly property int focusedIndex: root.orderedDevices.findIndex(d => d.address === root.focusedAddress)
  property string connectingAddress: ""
  property string failedAddress: ""
  property bool hasRequestedConnect: false

  signal closeRequested

  function sorted(list) {
    return list.slice().sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
  }

  function focusAt(index) {
    const count = root.orderedDevices.length;
    if (count === 0) {
      root.focusedAddress = "";
      return;
    }
    root.focusedAddress = root.orderedDevices[(index + count) % count].address;
  }

  function moveFocus(delta) {
    root.focusAt(root.focusedIndex < 0 ? 0 : root.focusedIndex + delta);
  }

  function toggleScan() {
    if (!root.isOn) {
      return;
    }
    root.adapter.discovering = !root.isScanning;
    if (root.adapter.discovering) {
      scanTimer.restart();
    }
  }

  function togglePower() {
    if (root.adapter) {
      root.adapter.enabled = !root.adapter.enabled;
    }
  }

  function activate(device) {
    if (!device) {
      return;
    }
    root.focusedAddress = device.address;
    if (root.connectingAddress === device.address) {
      // cancel
      if (device.pairing) {
        device.cancelPair();
      } else {
        device.disconnect();
      }
      root.connectingAddress = "";
      connectTimer.stop();
      return;
    }
    if (device.connected) {
      device.disconnect();
      return;
    }
    root.failedAddress = "";
    root.connectingAddress = device.address;
    root.hasRequestedConnect = false;
    connectTimer.restart();
    if (device.paired || device.bonded) {
      root.hasRequestedConnect = true;
      device.connect();
    } else {
      device.trusted = true;
      device.pair();
    }
  }

  implicitWidth: 360
  implicitHeight: 440
  focus: true

  Component.onCompleted: root.focusAt(0)
  Component.onDestruction: {
    if (root.isScanning && scanTimer.running) {
      root.adapter.discovering = false;
    }
  }

  onOrderedDevicesChanged: {
    if (root.focusedIndex < 0) {
      root.focusAt(0);
    }
  }

  onFocusedIndexChanged: Qt.callLater(() => {
    const item = rowItems[root.focusedAddress];
    if (item) {
      const y = item.mapToItem(listColumn, 0, 0).y;
      if (y < flickable.contentY) {
        flickable.contentY = Math.max(0, y - 24);
      } else if (y + item.height > flickable.contentY + flickable.height) {
        flickable.contentY = y + item.height - flickable.height;
      }
    }
  })

  // address -> row, for scrolling the focused one into view
  property var rowItems: ({})

  Keys.onPressed: event => {
    if (event.modifiers & (Qt.AltModifier | Qt.ControlModifier)) {
      return;
    }
    if (event.key === Qt.Key_Escape) {
      root.closeRequested();
    } else if (event.key === Qt.Key_Down) {
      root.moveFocus(1);
    } else if (event.key === Qt.Key_Up) {
      root.moveFocus(-1);
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.activate(root.orderedDevices[root.focusedIndex]);
    } else if (event.key === Qt.Key_S) {
      root.toggleScan();
    } else if (event.key === Qt.Key_T) {
      root.togglePower();
    } else {
      return;
    }
    event.accepted = true;
  }

  Timer {
    id: scanTimer

    interval: root.scanDuration
    onTriggered: {
      if (root.adapter) {
        root.adapter.discovering = false;
      }
    }
  }

  // BlueZ reports no failure for a device that never answers
  Timer {
    id: connectTimer

    interval: root.connectTimeout
    onTriggered: {
      root.failedAddress = root.connectingAddress;
      root.connectingAddress = "";
    }
  }

  // follows a connect through pair -> connect
  Timer {
    running: root.connectingAddress !== ""
    interval: 500
    repeat: true
    onTriggered: {
      const device = root.devices.find(d => d.address === root.connectingAddress);
      if (!device) {
        return;
      }
      if (device.connected) {
        root.connectingAddress = "";
        connectTimer.stop();
      } else if ((device.paired || device.bonded) && !device.pairing && !root.hasRequestedConnect) {
        root.hasRequestedConnect = true;
        device.connect();
      }
    }
  }

  StyledRectangularShadow {
    target: background
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: background

    anchors.fill: parent
    radius: Styles.radius.windowRounding
    color: Theme.options.mantle
    border.width: 1
    border.color: Theme.options.surface0
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    // header
    RowLayout {
      Layout.fillWidth: true
      Layout.margins: 12
      spacing: 10

      StyledRect {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 6
        color: root.isOn ? Theme.addAlpha(String(root.ink), 0.16) : Theme.options.surface0

        MaterialIcon {
          anchors.centerIn: parent
          icon: root.isOn ? "bluetooth" : "bluetooth_disabled"
          size: 18
          weight: Font.Normal
          color: root.isOn ? root.ink : root.overlay
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
          text: "Bluetooth"
          font.weight: Font.Medium
        }

        StyledText {
          text: {
            if (!root.adapter) {
              return "No adapter";
            }
            if (!root.isOn) {
              return "Off";
            }
            if (root.isScanning) {
              return "Discoverable · scanning";
            }
            if (root.connectedDevices.length > 0) {
              return `On · ${root.connectedDevices.length} connected`;
            }
            return root.pairedDevices.length > 0 ? "On" : "On · nothing paired";
          }
          color: root.subtext
          font.pixelSize: Styles.font.pixelSize.smaller
        }
      }

      StyledRect {
        Layout.preferredHeight: 28
        implicitWidth: scanRow.implicitWidth + 12
        radius: 6
        opacity: root.isOn ? 1 : 0.45
        color: scanMouseArea.containsMouse ? Theme.options.surface0 : "transparent"
        border.width: 1
        border.color: Theme.options.surface1

        RowLayout {
          id: scanRow

          anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
          }
          spacing: 6

          MaterialIcon {
            id: scanIcon

            icon: root.isScanning ? "progress_activity" : "refresh"
            size: root.isScanning ? 14 : 16
            weight: root.isScanning ? Font.Bold : Font.Normal
            color: root.isScanning ? root.ink : root.subtext

            RotationAnimation on rotation {
              running: root.isScanning
              from: 0
              to: 360
              duration: 800
              loops: Animation.Infinite
              onStopped: scanIcon.rotation = 0
            }
          }

          StyledText {
            text: root.isScanning ? "Scanning" : "Scan"
            font.pixelSize: Styles.font.pixelSize.small
          }

          KeyHints {
            hints: [
              {
                key: "S",
                text: ""
              }
            ]
            spacing: 0
            textColor: root.subtext
            keycapBorder: root.fieldBorder
          }
        }

        MouseArea {
          id: scanMouseArea

          anchors.fill: parent
          enabled: root.isOn
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.toggleScan()
        }
      }

      // power toggle
      StyledRect {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 20
        radius: 10
        color: root.isOn ? Theme.addAlpha(String(root.ink), 0.16) : Theme.options.surface0
        border.width: 1
        border.color: root.isOn ? root.ink : Theme.options.surface1

        StyledRect {
          x: root.isOn ? parent.width - width - 3 : 3
          anchors.verticalCenter: parent.verticalCenter
          width: 14
          height: 14
          radius: 7
          color: root.isOn ? root.ink : root.overlay

          Behavior on x {
            NumberAnimation {
              duration: Styles.animation.duration
              easing.type: Styles.animation.easingType
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePower()
        }
      }
    }

    StyledRect {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Theme.options.surface0
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      Flickable {
        id: flickable

        anchors {
          fill: parent
          topMargin: 4
          leftMargin: 6
          rightMargin: 6
          bottomMargin: 6
        }
        visible: root.isOn && root.sections.length > 0
        clip: true
        contentHeight: listColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: listColumn

          width: flickable.width
          spacing: 2

          Repeater {
            model: root.sections

            ColumnLayout {
              id: section

              required property var modelData

              Layout.fillWidth: true
              spacing: 2

              StyledText {
                Layout.leftMargin: 8
                Layout.topMargin: 8
                Layout.bottomMargin: 2
                text: section.modelData.label
                color: root.overlay
                font.pixelSize: Styles.font.pixelSize.smaller
                font.letterSpacing: Styles.font.pixelSize.smaller * 0.08
              }

              Repeater {
                model: section.modelData.devices

                BluetoothDeviceRow {
                  id: row

                  required property var modelData

                  Layout.fillWidth: true
                  device: row.modelData
                  isFocused: root.focusedAddress === row.device.address
                  isConnecting: root.connectingAddress === row.device.address
                  isFailed: root.failedAddress === row.device.address
                  ink: root.ink
                  subtext: root.subtext
                  overlay: root.overlay
                  onClicked: root.focusedAddress = row.device.address
                  onActivated: root.activate(row.device)
                  Component.onCompleted: root.rowItems[row.device.address] = row
                  Component.onDestruction: {
                    if (root.rowItems[row.device.address] === row) {
                      delete root.rowItems[row.device.address];
                    }
                  }
                }
              }
            }
          }
        }
      }

      // empty and off states
      ColumnLayout {
        anchors.centerIn: parent
        visible: !flickable.visible
        spacing: 6

        MaterialIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: root.isOn ? "devices_other" : "bluetooth_disabled"
          size: 32
          weight: Font.Normal
          color: root.overlay
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: !root.adapter ? "No Bluetooth adapter" : root.isOn ? "No known devices" : "Bluetooth is off"
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          visible: root.adapter !== null
          text: root.isOn ? "Press S to scan for nearby devices" : "Press T to turn it on"
          color: root.subtext
          font.pixelSize: Styles.font.pixelSize.small
        }
      }
    }

    StyledRect {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Theme.options.surface0
    }

    KeyHints {
      Layout.fillWidth: true
      Layout.margins: 12
      Layout.topMargin: 8
      Layout.bottomMargin: 8
      textColor: root.subtext
      keycapBorder: root.fieldBorder
      hints: root.isOn ? [
        {
          key: "↑↓",
          text: "select"
        },
        {
          key: "↵",
          text: "connect"
        },
        {
          key: "S",
          text: "scan"
        },
        {
          key: "T",
          text: "power"
        },
        {
          key: "Esc",
          text: "close"
        }
      ] : [
        {
          key: "T",
          text: "turn on"
        },
        {
          key: "Esc",
          text: "close"
        }
      ]
    }
  }
}
