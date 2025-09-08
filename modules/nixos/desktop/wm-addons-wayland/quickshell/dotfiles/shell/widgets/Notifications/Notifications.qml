import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.SNotifications

Scope {
  id: root

  LazyLoader {
    active: SNotifications.isPanelOpen
    component: NotificationsPanel {}
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
