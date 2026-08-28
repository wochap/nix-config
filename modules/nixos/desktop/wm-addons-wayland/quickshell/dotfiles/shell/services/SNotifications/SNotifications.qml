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
  readonly property int maxHistory: 100
  readonly property int defaultPopupTimeout: 5000
  property int idOffset // ensure unique notification id
  property int popupExitBatchCounter: 0
  property bool isPanelOpen: false
  property real lastSoundPlayedTime: 0
  readonly property int soundCooldownMs: 1000 // Only play a sound at most once per second

  // Whenever a state changes, re-evaluate the notification queue.
  onIsSilentChanged: processQueues()
  onIsIdleChanged: {
    // Layershell surfaces may miss pointer-leave events while blanked or
    // locked, leaving popup timers paused indefinitely.
    if (root.isIdle)
      root.arePopupsHovered = false;
    root.processQueues();
  }
  onIsLockedChanged: {
    root.arePopupsHovered = false;
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
    root.isPanelOpen = !root.isPanelOpen;
  }

  function resetPopupHover() {
    root.arePopupsHovered = false;
  }

  function trackedNotification(id) {
    return notificationServer.trackedNotifications.values.find(notification => notification.id + root.idOffset === id) ?? null;
  }

  function stopNotificationTimer(notification) {
    const timer = notification?.timer ?? null;
    if (!timer)
      return;
    notification.timer = null;
    timer.destroy();
  }

  function disposeNotification(notification, dismissOriginal = true) {
    if (!notification || notification.isDisposing)
      return;

    notification.isDisposing = true;
    root.stopNotificationTimer(notification);
    const original = dismissOriginal ? root.trackedNotification(notification.notificationId) : null;
    notification.destroy();
    if (original)
      original.dismiss();
  }

  function setHistory(notifications) {
    const next = notifications.slice(0, root.maxHistory);
    const evicted = notifications.slice(root.maxHistory);
    root.list = next;
    evicted.forEach(notification => root.disposeNotification(notification));
  }

  function schedulePersist() {
    persistTimer.restart();
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
      const hints = notification.notification?.hints ?? {};
      const wantsCustomSound = hints["custom-sound"] !== undefined;
      const customSound = hints["custom-sound"] || "message";
      const suppressSound = !!hints["suppress-sound"];

      if (wantsCustomSound && !suppressSound) {
        const now = Date.now();
        // Only play if enough time has passed since the last sound
        if (now - root.lastSoundPlayedTime > root.soundCooldownMs) {
          Quickshell.execDetached(["canberra-gtk-play", "-i", customSound]);
          root.lastSoundPlayedTime = now;
        }
      }

      if (notification?.notification?.expireTimeout !== 0) {
        notification.timer = notificationTimerComponent.createObject(root, {
          "notificationId": notification.notificationId,
          "duration": notification?.notification?.expireTimeout > 0 ? notification.notification.expireTimeout : defaultPopupTimeout,
          "paused": Qt.binding(() => root.arePopupsPaused)
        });
      }
    });
  }

  function requestPopupRemoval(id, discard, sourceTimer = null) {
    const notification = root.popupList.find(popup => popup.notificationId === id);
    if (!notification)
      return false;

    if (sourceTimer && notification.timer === sourceTimer)
      notification.timer = null;
    else
      root.stopNotificationTimer(notification);

    // Preserve content if the original notification disappears during exit.
    notification.cachedNotification = notification.toJSON();
    notification.discardAfterPopupExit = notification.discardAfterPopupExit || discard;
    notification.isPopupExiting = true;
    return true;
  }

  function finalizePopupRemoval(id) {
    const notification = root.popupList.find(popup => popup.notificationId === id);
    if (!notification || !notification.isPopupExiting)
      return;

    root.popupList = root.popupList.filter(popup => popup.notificationId !== id);
    if (root.popupList.length === 0)
      root.resetPopupHover();

    if (notification.discardAfterPopupExit) {
      root.disposeNotification(notification);
    } else if (!notification.isTransient) {
      if (notification.notification && notification.notification.expireTimeout > 0)
        notification.actions = [];

      if (notification.popupExitBatchId > 0) {
        const batch = [notification, ...root.list.filter(item => item.popupExitBatchId === notification.popupExitBatchId)];
        const previousHistory = root.list.filter(item => item.popupExitBatchId !== notification.popupExitBatchId);
        batch.sort((a, b) => a.popupExitHistoryOrder - b.popupExitHistoryOrder);
        root.setHistory([...batch, ...previousHistory]);
      } else {
        root.setHistory([notification, ...root.list]);
      }
    } else {
      root.disposeNotification(notification);
    }

    root.schedulePersist();
    root.processQueues();
  }

  function requestPanelRemoval(id) {
    const notification = root.list.find(item => item.notificationId === id);
    if (!notification || notification.isPanelExiting)
      return false;

    notification.cachedNotification = notification.toJSON();
    notification.isPanelExiting = true;
    return true;
  }

  function finalizePanelRemoval(id) {
    const notification = root.list.find(item => item.notificationId === id);
    if (!notification || !notification.isPanelExiting)
      return;

    root.list = root.list.filter(item => item.notificationId !== id);
    root.disposeNotification(notification);
    root.schedulePersist();
    root.processQueues();
  }

  function finalizePendingPanelRemovals() {
    const exiting = root.list.filter(notification => notification.isPanelExiting);
    if (exiting.length === 0)
      return;

    root.list = root.list.filter(notification => !notification.isPanelExiting);
    exiting.forEach(notification => root.disposeNotification(notification));
    root.schedulePersist();
    root.processQueues();
  }

  // Removes a notification entirely from the system.
  // Called when the user explicitly dismisses it.
  function discardNotification(id) {
    if (root.requestPopupRemoval(id, true))
      return;

    const historyNotification = root.list.find(notification => notification.notificationId === id);
    if (historyNotification && root.isPanelOpen) {
      root.requestPanelRemoval(id);
      return;
    }

    const notificationToDiscard = historyNotification
        || root.incomingQueue.find(notification => notification.notificationId === id);

    root.list = root.list.filter(n => n.notificationId !== id);
    root.incomingQueue = root.incomingQueue.filter(n => n.notificationId !== id);
    root.disposeNotification(notificationToDiscard);
    root.schedulePersist();
    root.processQueues();
  }

  // Removes all notifications from history and popups.
  function discardAllNotifications() {
    const history = [...root.list];
    const queued = [...root.incomingQueue];
    const popups = [...root.popupList];
    root.incomingQueue = [];

    if (root.isPanelOpen)
      history.forEach(notification => root.requestPanelRemoval(notification.notificationId));
    else {
      root.list = [];
      history.forEach(notification => root.disposeNotification(notification));
    }

    queued.forEach(notification => root.disposeNotification(notification));
    popups.forEach(notification => root.requestPopupRemoval(notification.notificationId, true));

    root.schedulePersist();
  }

  // Called when a notification pop-up times out.
  // It is moved from the popup list to the history list.
  function timeoutNotification(id, sourceTimer = null) {
    root.requestPopupRemoval(id, false, sourceTimer);
  }

  // Removes all currently visible popups without affecting history.
  function discardAllPopups() {
    const popups = [...root.popupList];
    popups.forEach(popup => root.requestPopupRemoval(popup.notificationId, true));
  }

  // Moves all currently visible pop-ups to the history list.
  function timeoutAllPopups() {
    const popups = [...root.popupList];
    const batchId = ++root.popupExitBatchCounter;
    popups.forEach((popup, index) => {
      popup.popupExitBatchId = batchId;
      popup.popupExitHistoryOrder = index;
      root.requestPopupRemoval(popup.notificationId, false);
    });
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

  Timer {
    id: persistTimer

    interval: 250
    onTriggered: notificationFileView.setText(root.stringifyList(root.list))
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
        "time": Date.now(),
        "isTransient": notification.transient
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
      onTimeout: (notificationId, timer) => {
        root.timeoutNotification(notificationId, timer);
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
      const cachedNotifications = JSON.parse(fileContents);
      root.list = cachedNotifications.slice(0, root.maxHistory).map(notification => {
        return notificationComponent.createObject(root, {
          "notificationId": notification.notificationId,
          "cachedNotification": notification
        });
      });
      let maxId = 0;
      root.list.forEach(notification => {
        maxId = Math.max(maxId, notification.notificationId);
      });
      root.idOffset = maxId;
      root.isReady = true;
      if (cachedNotifications.length > root.maxHistory)
        root.schedulePersist();
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        root.list = [];
        notificationFileView.setText(root.stringifyList(root.list));
      }
    }
  }
}
