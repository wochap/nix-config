pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.config
import qs.services

// Manages the full lifecycle of notifications, including:
// - A central queue for all incoming notifications.
// - State-aware processing (pausing, idle, lockscreen).
// - Manages on-screen popups and a persistent history.
// - Persistent storage.
Singleton {
  id: root

  // The main history of all notifications received. Used by the sidebar.
  property var list: []
  // A manually managed list of notifications currently visible as pop-ups.
  property var popupList: []
  // A temporary queue for all new notifications before they are processed.
  property list<SNotification> incomingQueue: []
  property bool isReady: false
  // State Flags to control notification flow
  property bool isSilent: false // User-toggled "Do Not Disturb"
  property bool isIdle: SIdle.isIdle
  property bool isLocked: SLock.isLock
  property bool arePopupsHovered: false
  property bool arePopupsPaused: isIdle || isLocked || arePopupsHovered || isPanelOpen
  readonly property int maxPopups: 5 // The maximum number of pop-ups to show on screen at once.
  readonly property int defaultPopupTimeout: 5000
  property int idOffset // ensure unique notification id
  property bool isPanelOpen: false

  // Whenever a state changes, re-evaluate the notification queue.
  onIsSilentChanged: processQueues()
  onIsIdleChanged: processQueues()
  onIsLockedChanged: {
    // If the screen becomes unlocked, process any notifications that arrived while it was locked.
    if (!root.isLocked) {
      processQueues();
    }
  }
  onIsPanelOpenChanged: {
    if (!root.isPanelOpen) {
      processQueues();
    }
  }

  function togglePanel() {
    root.isPanelOpen = !isPanelOpen;
  }

  // The central "gatekeeper" function. It decides when to show notifications
  // from the incomingQueue based on the current system state.
  function processQueues() {
    if (root.isSilent || root.isIdle || root.isLocked || root.isPanelOpen) {
      return;
    }

    const spaceAvailable = root.maxPopups - root.popupList.length;
    if (spaceAvailable <= 0 || root.incomingQueue.length === 0) {
      return;
    }

    // Determine which notifications to move without mutating the original queue yet.
    const notificationsToMove = root.incomingQueue.slice(0, spaceAvailable);

    // Create the new state for both lists.
    root.popupList = [...notificationsToMove, ...root.popupList];
    root.incomingQueue = root.incomingQueue.slice(notificationsToMove.length);

    // Create timers for the newly added popups.
    notificationsToMove.forEach(notification => {
      if (notification?.notification?.expireTimeout !== 0) {
        notification.timer = notificationTimerComponent.createObject(root, {
          "notificationId": notification.notificationId,
          "duration": notification?.notification?.expireTimeout > 0 ? notification.notification.expireTimeout : defaultPopupTimeout,
          "paused": Qt.binding(() => root.arePopupsPaused)
        });
      }
    });
  }

  // Removes a notification entirely from the system.
  // Called when the user explicitly dismisses it.
  function discardNotification(id) {
    // Create new lists by filtering out the discarded notification.
    root.list = root.list.filter(n => n.notificationId !== id);
    root.popupList = root.popupList.filter(n => n.notificationId !== id);

    // Tell the original notification server it was dismissed.
    const notificationServerIndex = notificationServer.trackedNotifications.values.findIndex(n => n.id + root.idOffset === id);
    if (notificationServerIndex !== -1) {
      notificationServer.trackedNotifications.values[notificationServerIndex].dismiss();
    }

    // Save changes and check if a new popup can be shown.
    notificationFileView.setText(root.stringifyList(root.list));
    root.processQueues();
  }

  // Removes all notifications from history and popups.
  function discardAllNotifications() {
    root.list = [];
    root.popupList = [];
    root.incomingQueue = [];

    notificationServer.trackedNotifications.values.forEach(notification => {
      notification.dismiss();
    });

    notificationFileView.setText(root.stringifyList(root.list));
  }

  // Called when a notification pop-up times out.
  // It is moved from the popup list to the history list.
  function timeoutNotification(id) {
    const timedOutNotification = root.popupList.find(n => n.notificationId === id);

    if (timedOutNotification) {
      // Create a new popupList without the timed-out notification.
      root.popupList = root.popupList.filter(n => n.notificationId !== id);
      // Create a new history list with the timed-out notification at the beginning.
      root.list = [timedOutNotification, ...root.list];

      // Persist the updated history list.
      notificationFileView.setText(root.stringifyList(root.list));
    }

    // A space has opened up, so process the queue for the next notification.
    root.processQueues();
  }

  // Removes all currently visible popups without affecting history.
  function discardAllPopups() {
    // Tell the notification server to dismiss each popup.
    root.popupList.forEach(popup => {
      const notificationServerIndex = notificationServer.trackedNotifications.values.findIndex(n => n.id + root.idOffset === popup.notificationId);
      if (notificationServerIndex !== -1) {
        notificationServer.trackedNotifications.values[notificationServerIndex].dismiss();
      }
    });

    // Clear the list of popups.
    root.popupList = [];

    // A space has opened up, so process the queue for the next notification(s).
    root.processQueues();
  }

  // Moves all currently visible pop-ups to the history list.
  function timeoutAllPopups() {
    if (root.popupList.length === 0) {
      return;
    }

    // Move all current popups to the main history list.
    root.list = [...root.popupList, ...root.list];

    // Clear the list of popups.
    root.popupList = [];

    // Persist the updated history list.
    notificationFileView.setText(root.stringifyList(root.list));

    // Check for new notifications to display.
    root.processQueues();
  }

  function attemptInvokeAction(id, actionIdentifier) {
    const notificationServerIndex = notificationServer.trackedNotifications.values.findIndex(notification => notification.id + root.idOffset === id);
    if (notificationServerIndex !== -1) {
      const notificationServerNotification = notificationServer.trackedNotifications.values[notificationServerIndex];
      const action = notificationServerNotification.actions.find(action => action.identifier === actionIdentifier);
      action.invoke();
    }
    root.discardNotification(id);
  }

  function toggleIsSilent() {
    root.isSilent = !root.isSilent;
  }

  function stringifyList(list) {
    return JSON.stringify(list.map(notification => notification.toJSON()), null, 2);
  }

  NotificationServer {
    id: notificationServer

    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    imageSupported: true
    keepOnReload: false
    persistenceSupported: true

    // This is the main entry point for all new notifications.
    onNotification: notification => {
      notification.tracked = true;
      const _notification = notificationComponent.createObject(root, {
        "notificationId": notification.id + root.idOffset,
        "notification": notification,
        "time": Date.now()
      });

      // Add to the incoming queue by creating a new array.
      root.incomingQueue = [...root.incomingQueue, _notification];
      root.processQueues();
    }
  }

  Component {
    id: notificationComponent

    SNotification {
      onDiscard: notificationId => {
        root.discardNotification(notificationId);
      }
    }
  }

  Component {
    id: notificationTimerComponent

    SNotificationTimer {
      onTimeout: notificationId => {
        root.timeoutNotification(notificationId);
      }
    }
  }

  // Grouping logic

  // property var latestTimeForApp: ({})
  // property var groupsByAppName: root.groupsForList(root.list)
  // property var popupGroupsByAppName: root.groupsForList(root.popupList)
  // property var appNameList: root.appNameListForGroups(root.groupsByAppName)
  // property var popupAppNameList: root.appNameListForGroups(root.popupGroupsByAppName)
  //
  // onListChanged: {
  //   root.list.forEach(notification => {
  //     if (!root.latestTimeForApp[notification.appName] || notification.time > root.latestTimeForApp[notification.appName]) {
  //       root.latestTimeForApp[notification.appName] = Math.max(root.latestTimeForApp[notification.appName] || 0, notification.time);
  //     }
  //   });
  //   Object.keys(root.latestTimeForApp).forEach(appName => {
  //     if (!root.list.some(notification => notification.appName === appName)) {
  //       delete root.latestTimeForApp[appName];
  //     }
  //   });
  // }
  //
  // function appNameListForGroups(groups) {
  //   return Object.keys(groups).sort((a, b) => {
  //     return groups[b].time - groups[a].time;
  //   });
  // }
  //
  // function groupsForList(list) {
  //   const groups = {};
  //   list.forEach(notification => {
  //     if (!groups[notification.appName]) {
  //       groups[notification.appName] = {
  //         appName: notification.appName,
  //         appIcon: notification.appIcon,
  //         notifications: [],
  //         time: 0
  //       };
  //     }
  //     groups[notification.appName].notifications.push(notification);
  //     groups[notification.appName].time = latestTimeForApp[notification.appName] || notification.time;
  //   });
  //   return groups;
  // }

  // File Persistence

  property var filePath: Paths.notificationsCache

  FileView {
    id: notificationFileView

    path: Qt.resolvedUrl(root.filePath)
    onLoaded: {
      const fileContents = notificationFileView.text();
      root.list = JSON.parse(fileContents).map(notification => {
        return notificationComponent.createObject(root, {
          "notificationId": notification.notificationId,
          "actions": [],
          "appIcon": notification.appIcon,
          "appName": notification.appName,
          "body": notification.body,
          "image": notification.image,
          "summary": notification.summary,
          "time": notification.time,
          "urgency": notification.urgency
        });
      });
      let maxId = 0;
      root.list.forEach(notification => {
        maxId = Math.max(maxId, notification.notificationId);
      });
      root.idOffset = maxId;
      root.isReady = true;
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        root.list = [];
        notificationFileView.setText(root.stringifyList(root.list));
      }
    }
  }
}
