import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import qs.config
import qs.services

QtObject {
  id: root

  required property int notificationId
  property Notification notification
  property list<var> actions: notification?.actions.map(action => ({
        "identifier": action.identifier,
        "text": action.text
      })) ?? []
  property string appIcon: notification?.appIcon ?? ""
  property string originalAppIcon: notification?.appIcon ?? ""
  // Render source for the icon: live value during the session, cached path after restore.
  readonly property string displayAppIcon: root.originalAppIcon !== "" ? root.originalAppIcon : root.appIcon
  property string appName: notification?.appName ?? ""
  property string body: sanitizeText(notification?.body ?? "")
  property string image: notification?.image ?? ""
  property string originalImage: notification?.image ?? ""
  // What to render now: the live source while the session owns it, falling back
  // to the cached file once restored from disk (originalImage is empty then).
  readonly property string displayImage: root.originalImage !== "" ? root.originalImage : root.image
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

  // Materialize the image to a stable cached file so it survives reload/restore.
  Component.onCompleted: {
    if (root.notification) {
      if (root.originalImage !== "") {
        const cachedUrl = SImageCache.cache(root.originalImage);
        if (cachedUrl !== "" && cachedUrl !== root.originalImage)
          root.image = cachedUrl;
      }
      // appIcon is either a themed icon name (persistent) or an image file path
      // (ephemeral) - only cache the latter. iconPath()/QIcon want a plain path,
      // not a file:// url, so strip it.
      if (SImageCache.isImagePath(root.originalAppIcon)) {
        const cachedIcon = SImageCache.cache(root.originalAppIcon);
        if (cachedIcon !== "" && cachedIcon !== root.originalAppIcon)
          root.appIcon = Paths.strip(cachedIcon);
      }
    }
  }

  property var imageCacheConnection: Connections {
    target: SImageCache

    function onCached(source, url) {
      if (!root.notification)
        return;
      if (source === root.originalImage)
        root.image = url;
      if (source === root.originalAppIcon)
        root.appIcon = Paths.strip(url);
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
