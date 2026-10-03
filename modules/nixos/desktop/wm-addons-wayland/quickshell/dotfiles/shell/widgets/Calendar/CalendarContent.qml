import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

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
  WlrLayershell.keyboardFocus: SCalendar.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  // covers the bar too, so a click on the bar (including the clock chip that
  // opened it) lands on the backdrop and closes the popover
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // click outside closes
  MouseArea {
    anchors.fill: parent
    enabled: SCalendar.isOpen
    onClicked: SCalendar.close()
  }

  Item {
    id: keyCatcher

    focus: true
    Keys.onEscapePressed: SCalendar.close()
  }

  // grows from the bar clock: scale .96→1, y −8→0, opacity 0→1
  Item {
    id: popover

    anchors {
      top: parent.top
      right: parent.right
      topMargin: (root.isFocusedClientFullScreen ? 0 : ConfigBar.barHeight) + ConfigCalendar.calendarMargin
      rightMargin: ConfigCalendar.calendarMargin
    }
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    transformOrigin: Item.TopRight
    opacity: 0
    scale: 0.96
    transform: Translate {
      id: slide

      y: -Styles.animation.slideDistance
    }

    states: State {
      name: "open"
      when: SCalendar.isOpen

      PropertyChanges {
        popover.opacity: 1
        popover.scale: 1
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
            script: SCalendar.finalizeClose()
          }
        }
      }
    ]

    // swallow clicks on the panel so they don't reach the backdrop
    MouseArea {
      anchors.fill: parent
    }

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
