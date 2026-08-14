import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.Bar.config
import qs.widgets.common
import "Utils.js" as Utils

PopupWindow {
  id: root

  required property Item anchorItem
  required property var clients
  required property var bindingForClient

  anchor.item: root.anchorItem
  anchor.edges: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Left) : (Edges.Bottom | Edges.Left)
  anchor.gravity: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Right) : (Edges.Bottom | Edges.Right)
  anchor.margins.top: ConfigBar.isBarAtBottom ? 4 : 0
  anchor.margins.bottom: ConfigBar.isBarAtBottom ? 0 : -4
  implicitWidth: popupContent.implicitWidth
  implicitHeight: popupContent.implicitHeight
  grabFocus: true
  color: "transparent"
  mask: Region {
    item: popupContent
  }

  WrapperRectangle {
    id: popupContent

    x: 0
    y: 0
    margin: 8
    color: Theme.options.backgroundOverlay
    radius: ConfigBar.modulesRadius
    focus: true
    Keys.onEscapePressed: root.visible = false
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    ColumnLayout {
      spacing: 8

      Repeater {
        model: root.clients

        RowLayout {
          spacing: 6

          StyledText {
            id: bindingLabel

            Layout.alignment: Qt.AlignVCenter
            text: root.bindingForClient(modelData)
            visible: bindingLabel.text.length > 0
            color: Theme.options.text
            font.pixelSize: Styles.font.pixelSize.small
          }

          SystemIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: Utils.mapAppId(modelData.class ?? "")
            size: Styles.font.pixelSize.normal
          }

          StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 140
            text: modelData.class ?? ""
            color: Theme.options.text
            font.pixelSize: Styles.font.pixelSize.small
            elide: Text.ElideMiddle
          }
        }
      }
    }
  }
}
