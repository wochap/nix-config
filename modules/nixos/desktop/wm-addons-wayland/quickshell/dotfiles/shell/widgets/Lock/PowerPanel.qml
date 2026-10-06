pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.Lock

// session actions from the lock screen, see design/project/PowerPanel.dc.html
// Single letters act only while this panel has focus.
FocusScope {
  id: root

  readonly property var rows: [
    {
      action: "stay",
      icon: "lock",
      label: "Stay locked",
      key: "Esc",
      isDanger: false
    },
    {
      action: "sleep",
      icon: "bedtime",
      label: "Sleep",
      key: "S",
      isDanger: false
    },
    {
      action: "restart",
      icon: "restart_alt",
      label: "Restart",
      key: "R",
      isDanger: true
    },
    {
      action: "shutdown",
      icon: "power_settings_new",
      label: "Shut down",
      key: "P",
      isDanger: true
    },
    {
      action: "logout",
      icon: "logout",
      label: "Log out",
      key: "L",
      isDanger: false
    }
  ]
  // opens on the safe row
  property int focusedIndex: 0

  signal closeRequested
  // sleep runs right away, the rest go through ConfirmDialog
  signal actionRequested(string action)

  function activate(action) {
    if (action === "stay") {
      root.closeRequested();
    } else {
      root.actionRequested(action);
    }
  }

  implicitWidth: ConfigLock.powerPanelWidth
  implicitHeight: column.implicitHeight + 12
  focus: true

  Keys.onPressed: event => {
    const byKey = {
      [Qt.Key_S]: "sleep",
      [Qt.Key_R]: "restart",
      [Qt.Key_P]: "shutdown",
      [Qt.Key_L]: "logout"
    };
    if (event.modifiers & (Qt.AltModifier | Qt.ControlModifier)) {
      return;
    }
    if (event.key === Qt.Key_Escape) {
      root.closeRequested();
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      root.activate(root.rows[root.focusedIndex].action);
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
      root.focusedIndex = (root.focusedIndex + 1) % root.rows.length;
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
      root.focusedIndex = (root.focusedIndex + root.rows.length - 1) % root.rows.length;
    } else if (byKey[event.key]) {
      root.activate(byKey[event.key]);
    } else {
      return;
    }
    event.accepted = true;
  }

  StyledRectangularShadow {
    target: background
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: background

    anchors.fill: parent
    radius: ConfigLock.radius
    color: Theme.options.mantle
    border.width: 1
    border.color: Theme.options.surface0
  }

  ColumnLayout {
    id: column

    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: 6
    }
    spacing: 6

    StyledText {
      Layout.leftMargin: 6
      Layout.topMargin: 6
      text: "POWER"
      color: ConfigLock.overlay
      font.pixelSize: Styles.font.pixelSize.smaller
      font.letterSpacing: Styles.font.pixelSize.smaller * 0.08
    }

    Repeater {
      model: root.rows

      Item {
        id: row

        required property var modelData
        required property int index
        readonly property bool isFocused: root.activeFocus && root.focusedIndex === row.index
        readonly property color tint: row.modelData.isDanger ? Theme.options.red : Theme.options.text

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Accessible.role: Accessible.Button
        Accessible.name: row.modelData.label
        Accessible.onPressAction: {
          root.focusedIndex = row.index;
          root.activate(row.modelData.action);
        }

        // focus ring: 2px mantle gap + 2px ink
        StyledRect {
          anchors {
            fill: parent
            margins: -4
          }
          visible: row.isFocused
          radius: ConfigLock.rowRadius + 4
          border.width: 2
          border.color: ConfigLock.ink
        }

        StyledRect {
          anchors.fill: parent
          radius: ConfigLock.rowRadius
          border.width: 1
          border.color: row.modelData.isDanger ? Theme.addAlpha(Theme.options.red, 0.4) : Theme.options.surface1
          color: {
            if (row.modelData.isDanger) {
              return Theme.addAlpha(Theme.options.red, rowMouseArea.containsMouse ? 0.16 : 0.08);
            }
            if (rowMouseArea.pressed) {
              return Theme.options.surface1;
            }
            return rowMouseArea.containsMouse ? Theme.options.surface0 : "transparent";
          }
        }

        RowLayout {
          anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 6
          }
          spacing: 10

          MaterialIcon {
            icon: row.modelData.icon
            size: 18
            weight: Font.Normal
            color: row.tint
          }

          StyledText {
            Layout.fillWidth: true
            text: row.modelData.label
            color: row.tint
            font.pixelSize: Styles.font.pixelSize.small
          }

          StyledRect {
            implicitWidth: keyText.implicitWidth + 8
            implicitHeight: 16
            radius: Styles.radius.small
            border.width: 1
            border.color: row.modelData.isDanger ? Theme.addAlpha(Theme.options.red, 0.5) : ConfigLock.fieldBorder

            StyledText {
              id: keyText

              anchors.centerIn: parent
              text: row.modelData.key
              color: row.modelData.isDanger ? Theme.options.red : ConfigLock.subtext
              font.pixelSize: Styles.font.pixelSize.smaller
              font.weight: Font.Medium
            }
          }
        }

        MouseArea {
          id: rowMouseArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.focusedIndex = row.index;
            root.activate(row.modelData.action);
          }
        }
      }
    }
  }
}
