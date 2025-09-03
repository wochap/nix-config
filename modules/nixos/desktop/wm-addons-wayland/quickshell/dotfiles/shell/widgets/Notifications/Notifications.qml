import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  property bool renderNotificationsPanel: false

  NotificationsPopups {}

  Loader {
    active: root.renderNotificationsPanel

    sourceComponent: NotificationsPanel {}
  }

  IpcHandler {
    target: "notificationsPanel"

    function toggle() {
      root.renderNotificationsPanel = !root.renderNotificationsPanel;
    }
  }
}
