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
  property string body: notification?.body ?? ""
  property string image: notification?.image ?? ""
  property string summary: notification?.summary ?? ""
  property double time
  property string urgency: notification?.urgency.toString() ?? "normal"
  property Timer timer

  signal discard(notificationId: int)

  onNotificationChanged: {
    if (root.notification === null) {
      root.discard(root.notificationId);
    }
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
