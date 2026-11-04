pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.widgets.common.status
import qs.widgets.VBar.config

ColumnLayout {
  id: root

  property bool isFocused: true
  spacing: ConfigVBar.modulesSpacing

  Capslock {
    vertical: true
  }

  IdleInhibit {
    vertical: true
  }

  Agents {
    vertical: true
  }

  Tt {
    vertical: true
  }

  SilentNotifications {
    vertical: true
  }

  Mail {
    vertical: true
  }

  Offlinemsmtp {
    vertical: true
  }

  Recorder {
    vertical: true
  }

  Wireguard {
    vertical: true
  }
}
