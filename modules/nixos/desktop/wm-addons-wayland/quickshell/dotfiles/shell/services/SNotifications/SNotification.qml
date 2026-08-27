import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import qs.services

QtObject {
  id: root

  required property int notificationId
  property Notification notification
  property var cachedNotification: null
  property list<var> actions: notification?.actions.map(action => ({
        "identifier": action.identifier,
        "text": action.text
      })) ?? []
  property string appIcon: notification?.appIcon ?? cachedNotification?.appIcon ?? ""
  property string appName: notification?.appName ?? cachedNotification?.appName ?? ""
  property string body: sanitizeText(notification?.body ?? cachedNotification?.body ?? "")
  property string image: notification?.image ?? cachedNotification?.image ?? ""
  property string summary: sanitizeText(notification?.summary ?? cachedNotification?.summary ?? "")
  property double time: cachedNotification?.time ?? 0
  property bool isTransient: notification?.transient ?? false
  property string urgency: notification?.urgency.toString() ?? cachedNotification?.urgency ?? "normal"
  property SNotificationTimer timer: null
  property bool isDisposing: false

  signal discard(notificationId: int)

  onNotificationChanged: {
    if (root.notification === null && !root.isDisposing) {
      root.discard(root.notificationId);
    }
  }

  property var retainableLock: RetainableLock {
    object: root.notification
    locked: root.notification !== null
  }

  // HTML & Tracking Pixel Stripper
  function sanitizeText(s) {
    if (!s)
      return "";
    // 1. Strip out <img> tags (prevents tracking pixels)
    let clean = s.replace(/<img\b[^>]*>/gi, "");
    // 2. Decode common HTML entities safely
    clean = clean.replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(parseInt(n, 10)));
    clean = clean.replace(/&#x([0-9a-fA-F]+);/g, (_, n) => String.fromCodePoint(parseInt(n, 16)));
    clean = clean.replace(/&([a-zA-Z][a-zA-Z0-9]*);/g, (match, name) => {
      const entities = {
        "amp": "&",
        "lt": "<",
        "gt": ">",
        "quot": "\"",
        "apos": "'",
        "nbsp": "\u00A0",
        "bull": "\u2022",
        "hellip": "\u2026",
        "copy": "\u00A9"
      };
      return entities[name] || match;
    });
    // 3. Trim surrounding whitespace and trailing line breaks, which otherwise
    // add empty space below the notification body.
    clean = clean.trim().replace(/(?:<br\b[^>]*>\s*)+$/gi, "");
    return clean.trim();
  }

  function toJSON() {
    return {
      "notificationId": root.notificationId,
      "actions": root.actions,
      "appIcon": root.appIcon,
      "appName": root.appName,
      "body": root.body,
      "image": root.image,
      "summary": root.summary,
      "time": root.time,
      "urgency": root.urgency
    };
  }
}
