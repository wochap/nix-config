import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

// Right sidebar: flat list, newest first
PanelWindow {
  id: root

  Component.onDestruction: SNotifications.finalizePendingPanelRemovals()

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2
  readonly property bool isEmpty: SNotifications.list.length === 0
  // horizontal offset of the sidebar, slides in from the right edge
  property real slideX: ConfigNotifications.notificationsPanelWidth

  WlrLayershell.namespace: "quickshell:notifications-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  screen: focusedScreen
  exclusionMode: isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: rectangle
  }

  RectangularShadowLeft {
    target: rectangle
  }

  // enter: slide right → left, exit: slide back out, same timing as the control center
  Item {
    id: slideState

    states: State {
      name: "open"
      when: SNotifications.isPanelOpen

      PropertyChanges {
        root.slideX: 0
      }
    }

    transitions: [
      Transition {
        to: "open"

        NumberAnimation {
          target: root
          property: "slideX"
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      },
      Transition {
        from: "open"

        SequentialAnimation {
          NumberAnimation {
            target: root
            property: "slideX"
            duration: Styles.animation.exitDuration
            easing.type: Styles.animation.exitEasingType
          }

          ScriptAction {
            script: SNotifications.finalizePanelClose()
          }
        }
      }
    ]
  }

  Rectangle {
    id: rectangle

    // slide with real geometry, not a Translate: the mask Region only tracks
    // geometry, a transform leaves it stuck at a mid-slide rect
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      rightMargin: -root.slideX
    }
    implicitWidth: ConfigNotifications.notificationsPanelWidth
    color: Theme.options.backgroundOverlay

    // 1px left border
    Rectangle {
      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
      }
      width: 1
      color: Theme.options.surface0
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ConfigNotifications.notificationsPanelPadding
      spacing: ConfigNotifications.notificationsPanelPadding

      // header
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        Layout.leftMargin: 4
        Layout.rightMargin: 2
        spacing: 8
        z: 1

        StyledText {
          text: "Notifications"
          font.pixelSize: Styles.font.pixelSize.normal
          font.weight: Font.Medium
        }

        Rectangle {
          visible: !root.isEmpty
          implicitWidth: countText.implicitWidth + 12
          implicitHeight: 16
          radius: 8
          color: Theme.options.primary

          StyledText {
            id: countText

            anchors.centerIn: parent
            text: SNotifications.list.length
            color: Theme.options.crust
            font.pixelSize: Styles.font.pixelSize.smaller
            font.weight: Font.Bold
          }
        }

        Item {
          Layout.fillWidth: true
        }

        DndSwitch {}

        NotificationButtonMd {
          horizontalPadding: 8
          materialIcon: "clear_all"
          text: "Clear"
          textWeight: Font.Normal
          fg: root.isEmpty ? Theme.options.surface2 : Theme.options.text
          enabled: !root.isEmpty
          onClicked: SNotifications.discardAllNotifications()
        }
      }

      // body
      SmoothListView {
        addDisplaced: Transition {
          id: addDisplacedTransition

          NumberAnimation {
            property: "y"
            duration: addDisplacedTransition.ViewTransition.item?.isEntering ? 0 : Styles.animation.duration
            easing.type: Styles.animation.easingType
          }
        }
        removeDisplaced: Transition {
          NumberAnimation {
            property: "y"
            duration: Styles.animation.duration
            easing.type: Styles.animation.easingType
          }
        }
        visible: !root.isEmpty
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: ConfigNotifications.notificationsSpacing
        clip: true
        // PERF: do granular updates with ScriptModel
        model: ScriptModel {
          values: SNotifications.list
        }
        delegate: NotificationPanelDelegate {}
      }

      // empty state
      ColumnLayout {
        visible: root.isEmpty
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6

        Item {
          Layout.fillHeight: true
        }

        MaterialIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: "notifications_off"
          size: 32
          color: Theme.options.surface1
          weight: Font.Normal
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: "All caught up"
          color: Theme.options.subtext0
          font.pixelSize: Styles.font.pixelSize.small
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: "New notifications land here · Super+Alt+N, N to toggle"
          color: Theme.options.overlay1
          font.pixelSize: Styles.font.pixelSize.smaller
        }

        Item {
          Layout.fillHeight: true
        }
      }
    }
  }

  // DND pill with a 26×16 switch
  component DndSwitch: Rectangle {
    id: dnd

    readonly property bool isOn: SNotifications.isSilent

    implicitWidth: dndRow.implicitWidth + 12
    implicitHeight: 24
    radius: 12
    color: dnd.isOn ? Theme.addAlpha(Theme.options.primary, Styles.tint.hover) : dndMouse.containsMouse ? Theme.options.surface1 : Theme.options.surface0

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }

    RowLayout {
      id: dndRow

      anchors {
        verticalCenter: parent.verticalCenter
        left: parent.left
        leftMargin: 8
      }
      spacing: 6

      MaterialIcon {
        icon: "do_not_disturb_on"
        size: 14
        weight: Font.Normal
        color: dnd.isOn ? Theme.options.primary : Theme.options.subtext0
      }

      StyledText {
        text: SNotifications.silencedCount > 0 ? `DND · ${SNotifications.silencedCount}` : "DND"
        color: dnd.isOn ? Theme.options.primary : Theme.options.subtext0
        font.pixelSize: Styles.font.pixelSize.smaller
        font.letterSpacing: 0.4
      }

      Rectangle {
        implicitWidth: 26
        implicitHeight: 16
        radius: 8
        color: dnd.isOn ? Theme.options.primary : Theme.options.surface1

        Rectangle {
          x: dnd.isOn ? 12 : 2
          anchors.verticalCenter: parent.verticalCenter
          width: 12
          height: 12
          radius: 6
          color: dnd.isOn ? Theme.options.crust : Theme.options.subtext0

          Behavior on x {
            animation: Styles.animations.numberAnimation.createObject(this)
          }
        }
      }
    }

    MouseArea {
      id: dndMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: SNotifications.toggleIsSilent()
    }
  }

  // shadow cast to the left of the sidebar
  component RectangularShadowLeft: StyledRectangularShadow {
    offset: Qt.vector2d(-8, 0)
    blur: 24
    spread: 0
    color: Theme.addAlpha(Theme.options.shadow, 0.35)
  }
}
