import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.Bar.config
import qs.widgets.ControlCenter
import qs.widgets.common
import "Utils.js" as Utils

PopupWindow {
  id: root

  required property Item anchorItem
  required property var clients
  required property var bindingForClient
  // requested state, drives the enter/exit animation, the window stays
  // visible until the exit animation finishes
  property bool isOpen: false
  readonly property real slideDistance: Styles.animation.slideDistance
  // same gap from the bar edge as the control center, the anchor item sits
  // barPaddingY inside the bar
  readonly property real barGap: ConfigBar.barPaddingY + ConfigControlCenter.controlCenterMargin

  function toggle() {
    root.isOpen = !root.isOpen;
  }

  onIsOpenChanged: {
    if (root.isOpen) {
      root.visible = true;
    }
  }
  // dismissed by the compositor (click outside)
  onVisibleChanged: {
    if (!root.visible) {
      root.isOpen = false;
    }
  }

  anchor.item: root.anchorItem
  anchor.edges: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Left) : (Edges.Bottom | Edges.Left)
  anchor.gravity: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Right) : (Edges.Bottom | Edges.Right)
  // the window is taller by slideDistance on the bar side, room for the slide
  // so the content isn't clipped, the margins compensate for it
  anchor.margins.top: ConfigBar.isBarAtBottom ? -(root.barGap - root.slideDistance) : 0
  anchor.margins.bottom: ConfigBar.isBarAtBottom ? 0 : -(root.barGap - root.slideDistance)
  implicitWidth: popupContent.implicitWidth
  implicitHeight: popupContent.implicitHeight + root.slideDistance
  grabFocus: true
  color: "transparent"
  mask: Region {
    item: popupContent
  }

  WrapperRectangle {
    id: popupContent

    x: 0
    y: ConfigBar.isBarAtBottom ? 0 : root.slideDistance
    transformOrigin: ConfigBar.isBarAtBottom ? Item.BottomLeft : Item.TopLeft
    opacity: 0
    scale: 0.96
    transform: Translate {
      id: slide

      // slides in from the bar
      y: ConfigBar.isBarAtBottom ? root.slideDistance : -root.slideDistance
    }

    states: State {
      name: "open"
      when: root.isOpen

      PropertyChanges {
        popupContent.opacity: 1
        popupContent.scale: 1
        slide.y: 0
      }
    }

    transitions: [
      Transition {
        to: "open"

        NumberAnimation {
          properties: "opacity,scale,y"
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      },
      Transition {
        from: "open"

        SequentialAnimation {
          NumberAnimation {
            properties: "opacity,scale,y"
            duration: Styles.animation.exitDuration
            easing.type: Styles.animation.exitEasingType
          }

          ScriptAction {
            script: {
              if (!root.isOpen) {
                root.visible = false;
              }
            }
          }
        }
      }
    ]

    margin: 8
    color: Theme.options.backgroundOverlay
    radius: ConfigBar.modulesRadius
    focus: true
    Keys.onEscapePressed: root.isOpen = false
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
