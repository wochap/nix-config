import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.SNotifications

Scope {
  id: root

  Loader {
    active: SNotifications.isPanelOpen
    sourceComponent: NotificationsPanel {}
  }

  NotificationsPopups {}

  IpcHandler {
    target: "notifications"

    function togglePanel() {
      SNotifications.togglePanel();
    }

    function discardPopups() {
      SNotifications.discardAllPopups();
    }

    function dismissPopups() {
      SNotifications.timeoutAllPopups();
    }
  }
}
