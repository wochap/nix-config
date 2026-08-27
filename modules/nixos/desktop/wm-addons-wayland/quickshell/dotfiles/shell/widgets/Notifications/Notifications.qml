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

  LazyLoader {
    active: SNotifications.popupList.length > 0
    component: NotificationsPopups {}
  }

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
