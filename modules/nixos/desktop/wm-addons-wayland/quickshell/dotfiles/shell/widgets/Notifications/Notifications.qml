import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.services.SNotifications

Scope {
  id: root

  LazyLoader {
    active: SNotifications.isPanelOpen
    component: NotificationsPanel {}
  }

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

  // Keep the window alive so the first add and last removal can animate.
  // Recreate it when the output disappears: the compositor closes the layer
  // surface with its output and Quickshell never remaps it, so popups would
  // stay hidden and stuck in popupList until the shell restarts.
  LazyLoader {
    active: root.focusedScreen !== null
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
