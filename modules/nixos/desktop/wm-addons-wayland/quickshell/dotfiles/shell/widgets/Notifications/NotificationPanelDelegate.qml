import QtQuick
import qs.config
import qs.services.SNotifications

Item {
  id: root

  required property int index
  required property SNotification modelData
  // ScriptModel may invalidate modelData before a retained delegate is destroyed.
  property SNotification retainedModelData: modelData
  readonly property bool isEntering: enterAnimation.running

  NumberAnimation {
    id: enterAnimation

    target: root
    property: "opacity"
    to: 1
    duration: Styles.animation.duration
    easing.type: Styles.animation.easingType
  }

  property real xOffset: 0

  ParallelAnimation {
    id: exitAnimation

    NumberAnimation {
      target: root
      property: "opacity"
      to: 0
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    NumberAnimation {
      target: root
      property: "xOffset"
      to: ConfigNotifications.notificationExitDistance
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    onStopped: {
      const notification = root.retainedModelData;
      if (notification?.isPanelExiting ?? false)
        SNotifications.finalizePanelRemoval(notification.notificationId);
    }
  }

  function startExit() {
    if (exitAnimation.running)
      return;

    enterAnimation.stop();
    exitAnimation.start();
  }

  // Rows populated with the panel do not receive ListView.onAdd.
  opacity: 1
  z: (retainedModelData?.isPanelExiting ?? false) ? -1 : (isEntering ? 1 : 0)
  implicitHeight: notificationItem.implicitHeight
  anchors.left: parent?.left
  anchors.right: parent?.right
  transform: Translate {
    x: root.xOffset
  }

  Component.onCompleted: {
    root.retainedModelData = root.modelData;
    if (root.retainedModelData.isPanelExiting)
      root.startExit();
  }

  ListView.onAdd: {
    root.opacity = 0;
    enterAnimation.start();
  }

  NotificationItem {
    id: notificationItem

    index: root.index
    modelData: root.retainedModelData
    isPopup: false
    height: implicitHeight
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
  }

  Connections {
    target: root.retainedModelData

    function onIsPanelExitingChanged() {
      if (root.retainedModelData.isPanelExiting)
        root.startExit();
    }
  }
}
