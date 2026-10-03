import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets.common

PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2

  screen: root.focusedScreen
  WlrLayershell.namespace: "quickshell:calendar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: root.isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: popover
  }

  HyprlandFocusGrab {
    // armed after the first frame so the click that opened the popover doesn't clear it
    active: grabTimer.armed && SCalendar.isOpen
    windows: [root]
    onCleared: SCalendar.close()
  }

  Timer {
    id: grabTimer

    property bool armed: false

    interval: 50
    running: true
    onTriggered: armed = true
  }

  // grows from the bar clock: scale .96→1, y −8→0, opacity 0→1
  Item {
    id: popover

    property bool shown: false
    readonly property bool isVisible: popover.shown && SCalendar.isOpen
    readonly property int duration: SCalendar.isOpen ? Styles.animation.duration : Styles.animation.exitDuration
    readonly property int easingType: SCalendar.isOpen ? Styles.animation.easingType : Styles.animation.exitEasingType

    anchors {
      top: parent.top
      right: parent.right
      topMargin: ConfigCalendar.calendarMargin
      rightMargin: ConfigCalendar.calendarMargin
    }
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    transformOrigin: Item.TopRight
    opacity: popover.isVisible ? 1 : 0
    scale: popover.isVisible ? 1 : 0.96
    transform: Translate {
      y: popover.isVisible ? 0 : -Styles.animation.slideDistance

      Behavior on y {
        NumberAnimation {
          duration: popover.duration
          easing.type: popover.easingType
        }
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: popover.duration
        easing.type: popover.easingType
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: popover.duration
        easing.type: popover.easingType
      }
    }

    Component.onCompleted: popover.shown = true

    StyledRectangularShadow {
      target: panel
      elevation: Styles.elevation.e2
    }

    StyledRect {
      id: panel

      anchors.fill: parent
      implicitWidth: ConfigCalendar.calendarWidth
      implicitHeight: content.implicitHeight + ConfigCalendar.calendarPadding * 2
      radius: Styles.radius.windowRounding
      color: Theme.options.background
      border {
        width: 1
        color: Theme.options.surface0
      }

      Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: SCalendar.close()
      }

      ColumnLayout {
        id: content

        anchors {
          fill: parent
          margins: ConfigCalendar.calendarPadding
        }
        spacing: ConfigCalendar.calendarSpacing

        // Time + date
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          StyledText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: Styles.font.pixelSize.huge
            font.weight: Font.Medium
            lineHeight: 26
            lineHeightMode: Text.FixedHeight
          }

          StyledText {
            text: `${Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")} · W${monthGrid.isoWeek(clock.date)}`
            font.pixelSize: Styles.font.pixelSize.small
            color: Theme.options.subtext0
          }
        }

        CalendarMonthGrid {
          id: monthGrid

          Layout.fillWidth: true
          today: clock.date
        }

        CalendarWeatherCard {
          Layout.fillWidth: true
        }

        CalendarAgenda {
          Layout.fillWidth: true
        }
      }
    }
  }

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  Component.onCompleted: {
    SKhal.refresh();
    if (!SWeather.available)
      SWeather.refresh();
  }
}
