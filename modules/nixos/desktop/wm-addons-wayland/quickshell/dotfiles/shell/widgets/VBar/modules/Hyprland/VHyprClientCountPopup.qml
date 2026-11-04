import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.VBar.config
import qs.widgets.common
import "Utils.js" as Utils

PopupWindow {
  id: root

  required property Item anchorItem
  required property var clients
  required property var bindingForClient
  property string label: ""
  property bool isOpen: false

  function toggle() {
    root.isOpen = !root.isOpen;
  }

  function focusClient(client) {
    if (!client?.address) return;
    const window = `"address:${client.address}"`;
    const raise = client.floating ? `hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = ${window} }))` : "";
    Quickshell.execDetached(["hyprctl", "eval", `
      local no_warps = hl.get_config("cursor.no_warps")
      hl.config({ cursor = { no_warps = true } })
      hl.dispatch(hl.dsp.focus({ window = ${window} }))
      ${raise}
      hl.config({ cursor = { no_warps = no_warps } })
    `]);
  }

  visible: root.isOpen
  onVisibleChanged: {
    if (!root.visible) {
      root.isOpen = false;
    }
  }

  anchor.item: root.anchorItem
  anchor.edges: Edges.Right | Edges.Top
  anchor.gravity: Edges.Right | Edges.Bottom
  anchor.margins.right: 2
  anchor.margins.top: -12

  implicitWidth: popupCard.implicitWidth + 24
  implicitHeight: popupCard.implicitHeight + 24
  grabFocus: true
  color: "transparent"
  mask: Region {}

  StyledRectangularShadow {
    target: popupCard
    elevation: Styles.elevation.e1
  }

  StyledRect {
    id: popupCard

    anchors.centerIn: parent
    implicitWidth: Math.max(140, cardCol.implicitWidth + 16)
    implicitHeight: cardCol.implicitHeight + 16
    radius: 8
    color: Theme.options.base
    border.width: 1
    border.color: Theme.options.surface0
    focus: true
    Keys.onEscapePressed: root.isOpen = false

    ColumnLayout {
      id: cardCol

      x: 8
      y: 8
      spacing: 4

      StyledText {
        text: (root.label.length > 0 ? root.label.toUpperCase() : "WINDOWS") + ` · ${root.clients.length}`
        font.pixelSize: 10
        font.weight: 600
        font.letterSpacing: 0.6
        color: Theme.options.subtext0
        Layout.leftMargin: 4
        Layout.bottomMargin: 2
      }

      Repeater {
        model: root.clients

        Rectangle {
          id: itemRow

          required property var modelData

          Layout.fillWidth: true
          implicitWidth: rowLayout.implicitWidth + 12
          implicitHeight: 28
          radius: 6
          color: itemMouseArea.pressed ? Theme.options.surface2 : itemMouseArea.containsMouse ? Theme.options.surface1 : "transparent"

          Behavior on color {
            animation: Styles.animations.colorAnimation.createObject(this)
          }

          MouseArea {
            id: itemMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.focusClient(itemRow.modelData);
              root.isOpen = false;
            }
          }

          RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Rectangle {
              id: keyBadge

              readonly property string key: root.bindingForClient(itemRow.modelData)
              visible: key.length > 0
              Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
              implicitWidth: keyLabel.implicitWidth + 8
              implicitHeight: 18
              radius: 4
              color: Theme.options.surface0

              StyledText {
                id: keyLabel

                anchors.centerIn: parent
                text: keyBadge.key
                font.pixelSize: 10
                font.weight: 600
                color: Theme.options.primary
              }
            }

            SystemIcon {
              Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
              icon: Utils.mapAppId(itemRow.modelData.class ?? "")
              size: 16
            }

            StyledText {
              Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
              Layout.fillWidth: true
              Layout.maximumWidth: 180
              horizontalAlignment: Text.AlignLeft
              text: itemRow.modelData.title || itemRow.modelData.class || ""
              color: itemMouseArea.containsMouse ? Theme.options.text : Theme.options.subtext1
              font.pixelSize: 11
              font.weight: 500
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
