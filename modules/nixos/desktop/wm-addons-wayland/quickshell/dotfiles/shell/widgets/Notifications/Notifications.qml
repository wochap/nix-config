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

  // Keep the window alive so the first add and last removal can animate.
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

    function discard(id: int) {
      SNotifications.discardNotification(id);
    }
  }
}
