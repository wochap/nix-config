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
  property string urgency: normalizeUrgency(notification?.urgency ?? cachedNotification?.urgency ?? 1)
  property string desktopEntry: notification?.desktopEntry ?? cachedNotification?.desktopEntry ?? ""
  // Only shell-specific hints are kept, the rest can be large or short-lived
  property var shellHints: pickShellHints(notification?.hints ?? cachedNotification?.hints ?? {})
  // x-shell-meta / x-shell-foot: small lines above and below the body
  readonly property string meta: sanitizeText(shellHints["x-shell-meta"] ?? "")
  readonly property string foot: sanitizeText(shellHints["x-shell-foot"] ?? "")
  readonly property bool isCritical: urgency === "critical"
  readonly property bool isLow: urgency === "low"
  // Small icon shown next to appName, never a preview or a contact avatar
  readonly property string headerIcon: resolveHeaderIcon()
  // Thumbnail written to the cache dir, survives restarts
  property string persistedThumb: cachedNotification?.thumb ?? ""
  // 56px thumbnail, x-shell-preview wins over the image hint and file app icons
  readonly property string thumb: persistedThumb || resolveThumb()
  property SNotificationTimer timer: null
  property bool isDisposing: false
  property bool isPopupExiting: false
  property bool isPanelExiting: false
  property bool discardAfterPopupExit: false
  property int popupExitBatchId: 0
  property int popupExitHistoryOrder: -1

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

  function normalizeUrgency(value) {
    const urgency = String(value).toLowerCase();
    if (urgency === "0" || urgency === "low")
      return "low";
    if (urgency === "2" || urgency === "critical")
      return "critical";
    return "normal";
  }

  function pickShellHints(hints) {
    const picked = {};
    for (const key of Object.keys(hints ?? {})) {
      if (key.startsWith("x-shell-"))
        picked[key] = String(hints[key]);
    }
    return picked;
  }

  function isPath(value) {
    return value.startsWith("/") || value.startsWith("file:");
  }

  function toFileUrl(value) {
    return value.startsWith("/") ? `file://${value}` : value;
  }

  // Quickshell turns image-path hints into image://icon/<name> (themed icon)
  // or image://icon//<abs path> (file), image-data into image://qsimage/...
  function iconNameFromImage(value) {
    if (value.startsWith("image://icon/") && !value.startsWith("image://icon//"))
      return value.slice("image://icon/".length);
    return "";
  }

  function resolveThumb() {
    const preview = root.shellHints["x-shell-preview"] ?? "";
    if (preview.length > 0)
      return root.toFileUrl(preview);
    const image = root.image;
    if (image.startsWith("image://icon//"))
      return `file://${image.slice("image://icon/".length)}`;
    if (image.length > 0 && !image.startsWith("image://icon/"))
      return image;
    // e.g. chat apps sending the contact avatar as app icon
    if (root.isPath(root.appIcon))
      return root.toFileUrl(root.appIcon);
    return "";
  }

  function resolveHeaderIcon() {
    if (root.appIcon.length > 0 && !root.isPath(root.appIcon))
      return root.appIcon;
    const entry = root.desktopEntry.length > 0 ? DesktopEntries.heuristicLookup(root.desktopEntry) : null;
    if (entry?.icon)
      return entry.icon;
    const imageIcon = root.iconNameFromImage(root.image);
    if (imageIcon.length > 0)
      return imageIcon;
    const appEntry = root.appName.length > 0 ? DesktopEntries.heuristicLookup(root.appName) : null;
    if (appEntry?.icon)
      return appEntry.icon;
    return root.appName.toLowerCase();
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
      "urgency": root.urgency,
      "desktopEntry": root.desktopEntry,
      "hints": root.shellHints,
      // qsimage urls die with the notification, only keep files
      "thumb": root.persistedThumb || (root.thumb.startsWith("image://qsimage") ? "" : root.thumb)
    };
  }
}
