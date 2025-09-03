import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  property bool renderNotificationsPanel: false

  Loader {
    active: root.renderNotificationsPanel

    sourceComponent: NotificationsPanel {}
  }

  NotificationsPopups {}

  IpcHandler {
    target: "notificationsPanel"

    function toggle() {
      root.renderNotificationsPanel = !root.renderNotificationsPanel;
    }
  }
}
