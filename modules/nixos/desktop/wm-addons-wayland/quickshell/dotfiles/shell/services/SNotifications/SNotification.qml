import Quickshell
import QtQuick
import Quickshell.Services.Notifications

QtObject {
  id: root

  required property int notificationId
  property Notification notification
  property list<var> actions: notification?.actions.map(action => ({
        "identifier": action.identifier,
        "text": action.text
      })) ?? []
  property string appIcon: notification?.appIcon ?? ""
  property string appName: notification?.appName ?? ""
  property string body: sanitizeText(notification?.body ?? "")
  property string image: notification?.image ?? ""
  property string summary: sanitizeText(notification?.summary ?? "")
  property double time
  property bool isTransient: notification?.transient ?? false
  property string urgency: notification?.urgency.toString() ?? "normal"
  property SNotificationTimer timer: null

  signal discard(notificationId: int)

  onNotificationChanged: {
    if (root.notification === null) {
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
    return clean;
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
