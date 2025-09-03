import QtQuick
import Quickshell

Scope {
  id: root

  required property int notificationId
  required property int duration
  property bool paused: false
  property real progress: 1.0
  signal timeout(notificationId: int)

  NumberAnimation {
    target: root
    property: "progress"
    from: 1.0
    to: 0.0
    duration: root.duration
    running: true
    paused: root.paused
    onFinished: {
      root.timeout(root.notificationId);
      destroy();
    }
  }
}
