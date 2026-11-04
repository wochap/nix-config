import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import "HyprUtils.js" as Utils

// Popover listing Hyprland clients (key badge · app icon · title). Clicking a
// row focuses the client without warping the cursor. Callers set `anchor.*`.
PopupCard {
  id: root

  required property Item anchorItem
  required property var clients
  required property var bindingForClient
  property string label: ""

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

  anchor.item: root.anchorItem
  minCardWidth: 140
  cardSpacing: 4
  closeOnEscape: true

  PopupCardHeader {
    text: (root.label.length > 0 ? root.label.toUpperCase() : "WINDOWS") + ` · ${root.clients.length}`
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
