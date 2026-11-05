import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import qs.widgets.common.status
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.SysTray

RowLayout {
  id: root

  required property bool isFocused

  spacing: ConfigBar.modulesSpacing

  SysTray {
    id: sysTray

    visible: isFocused && sysTray.hasItems
    Layout.fillHeight: true
  }

  RowLayout {
    Layout.fillHeight: true
    // HACK: MaterialIcon offset
    Layout.leftMargin: ConfigBar.modulesSpacing
    spacing: ConfigBar.modulesSpacing
    visible: isFocused && (capslock.isVisible || tt.isVisible || idleInhibit.isVisible || agents.isVisible || mail.isVisible || offlinemsmtp.isVisible || recorder.isVisible || wireguard.isVisible || notifications.isVisible)

    Capslock {
      id: capslock

      Layout.fillHeight: true
    }

    Agents {
      id: agents

      Layout.fillHeight: true
    }

    // Timewarrior {
    //   id: timewarrior
    //
    //   Layout.fillHeight: true
    // }

    Tt {
      id: tt

      Layout.fillHeight: true
    }

    SilentNotifications {
      id: notifications

      Layout.fillHeight: true
    }

    Mail {
      id: mail

      Layout.fillHeight: true
    }

    Offlinemsmtp {
      id: offlinemsmtp

      Layout.fillHeight: true
    }

    Recorder {
      id: recorder

      Layout.fillHeight: true
    }

    Wireguard {
      id: wireguard

      Layout.fillHeight: true
    }

    IdleInhibit {
      id: idleInhibit

      Layout.fillHeight: true
    }
  }

  RowLayout {
    Layout.fillHeight: true
    spacing: 0

    Control {
      visible: isFocused
      Layout.fillHeight: true
    }

    Clock {
      Layout.fillHeight: true
    }
  }
}
