import QtQuick

Timer {
  id: root

  required property int notificationId
  signal timeout(notificationId: int)

  running: true
  onTriggered: () => {
    root.timeout(root.notificationId);
    destroy();
  }
}
