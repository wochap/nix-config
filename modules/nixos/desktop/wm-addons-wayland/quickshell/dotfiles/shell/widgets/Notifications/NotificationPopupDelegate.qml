import QtQuick
import qs.config
import qs.services.SNotifications

Item {
  id: root

  required property int index
  required property SNotification modelData
  // exit slide, the enter slide is Styles.animation.slideDistance on y
  property real slideDistance: ConfigNotifications.notificationExitDistance
  // ScriptModel may invalidate modelData before a retained delegate is destroyed.
  property SNotification retainedModelData: modelData
  property real xOffset: 0
  property real yOffset: 0
  readonly property bool isEntering: enterAnimation.running

  ParallelAnimation {
    id: enterAnimation

    NumberAnimation {
      target: root
      property: "yOffset"
      to: 0
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
    NumberAnimation {
      target: root
      property: "opacity"
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
    onStopped: {
      if (!exitAnimation.running) {
        root.yOffset = 0;
        root.opacity = 1;
      }
    }
  }

  ParallelAnimation {
    id: exitAnimation

    NumberAnimation {
      target: root
      property: "xOffset"
      to: root.slideDistance
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    NumberAnimation {
      target: root
      property: "opacity"
      to: 0
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    onStopped: {
      const notification = root.retainedModelData;
      if (notification?.isPopupExiting ?? false)
        SNotifications.finalizePopupRemoval(notification.notificationId);
    }
  }

  function startExit() {
    if (exitAnimation.running)
      return;

    enterAnimation.stop();
    exitAnimation.start();
  }

  opacity: 0
  z: exitAnimation.running ? -1 : (isEntering ? 1 : 0)
  implicitHeight: notificationItem.implicitHeight
  anchors.left: parent?.left
  anchors.right: parent?.right
  transform: Translate {
    x: root.xOffset
    y: root.yOffset
  }

  Component.onCompleted: {
    root.retainedModelData = root.modelData;
    if (root.retainedModelData.isPopupExiting) {
      root.startExit();
    } else {
      // Popups already in the model when the window is recreated never get
      // ListView.onAdd, so animate them in here.
      root.yOffset = -Styles.animation.slideDistance;
      enterAnimation.start();
    }
  }

  ListView.onAdd: {
    root.yOffset = -Styles.animation.slideDistance;
    root.opacity = 0;
    enterAnimation.start();
  }
  ListView.delayRemove: exitAnimation.running
  ListView.onRemove: {
    if (root.opacity > 0)
      root.startExit();
  }

  NotificationItem {
    id: notificationItem

    index: root.index
    modelData: root.retainedModelData
    isPopup: true
    height: implicitHeight
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
  }

  Connections {
    target: root.retainedModelData

    function onIsPopupExitingChanged() {
      if (root.retainedModelData.isPopupExiting)
        root.startExit();
    }
  }
}
