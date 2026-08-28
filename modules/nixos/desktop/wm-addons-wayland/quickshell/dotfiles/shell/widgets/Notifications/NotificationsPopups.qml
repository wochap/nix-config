import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications

PanelWindow {
  id: root

  Component.onDestruction: SNotifications.resetPopupHover()

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2

  WlrLayershell.namespace: "quickshell:notifications-popups"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    bottom: true
    right: true
    left: true
  }
  screen: focusedScreen
  exclusionMode: isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: listview.contentItem
  }

  ListView {
    id: listview

    // Existing popups should move down when queued popups are inserted. A
    // popup from the same rapidly inserted batch can also become displaced;
    // place those directly so their entrance remains slide/fade-only.
    addDisplaced: Transition {
      id: popupAddDisplacedTransition

      NumberAnimation {
        property: "y"
        duration: popupAddDisplacedTransition.ViewTransition.item?.isEntering ? 0 : Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }
    // Once an exiting popup has finished its own animation and leaves the
    // model, smoothly close the gap for the delegates that remain.
    removeDisplaced: Transition {
      NumberAnimation {
        property: "y"
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      topMargin: 8
      rightMargin: anchors.topMargin
    }
    bottomMargin: anchors.topMargin
    implicitWidth: ConfigNotifications.notificationsPopupsWidth
    spacing: ConfigNotifications.notificationsSpacing
    clip: false
    // PERF: do granular updates with ScriptModel
    model: ScriptModel {
      values: SNotifications.popupList
    }
    delegate: Item {
      id: popupDelegate

      required property int index
      required property SNotification modelData
      // ScriptModel can invalidate modelData while retaining a removed row.
      property SNotification retainedModelData: modelData
      property real popupOffset: 0
      readonly property bool isEntering: popupAddAnimation.running

      property ParallelAnimation popupAddAnimation: ParallelAnimation {
        NumberAnimation {
          target: popupDelegate
          property: "popupOffset"
          to: 0
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        NumberAnimation {
          target: popupDelegate
          property: "opacity"
          to: 1
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        onStopped: {
          if (!popupRemoveAnimation.running) {
            popupDelegate.popupOffset = 0;
            popupDelegate.opacity = 1;
          }
        }
      }
      property ParallelAnimation popupRemoveAnimation: ParallelAnimation {
        NumberAnimation {
          target: popupDelegate
          property: "popupOffset"
          to: listview.width
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        NumberAnimation {
          target: popupDelegate
          property: "opacity"
          to: 0
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        onStopped: {
          const notification = popupDelegate.retainedModelData;
          if (notification?.isPopupExiting ?? false)
            SNotifications.finalizePopupRemoval(notification.notificationId);
        }
      }

      function startRemoval() {
        if (popupRemoveAnimation.running)
          return;

        popupAddAnimation.stop();
        popupRemoveAnimation.start();
      }

      opacity: 0
      Component.onCompleted: {
        popupDelegate.retainedModelData = popupDelegate.modelData;
        if (popupDelegate.retainedModelData.isPopupExiting)
          popupDelegate.startRemoval();
      }
      ListView.onAdd: {
        popupDelegate.popupOffset = listview.width;
        popupDelegate.opacity = 0;
        popupAddAnimation.start();
      }
      // Preserve the slide/fade if a popup is unexpectedly removed directly
      // from the model instead of through the notification service.
      ListView.delayRemove: popupRemoveAnimation.running
      ListView.onRemove: {
        // Service-managed removals finish before changing the model. This is
        // a safety fallback for an unexpected direct model removal.
        if (popupDelegate.popupOffset < listview.width) {
          popupDelegate.startRemoval();
        }
      }

      z: popupRemoveAnimation.running ? -1 : (popupAddAnimation.running ? 1 : 0)
      implicitHeight: popupItem.implicitHeight
      anchors.left: parent?.left
      anchors.right: parent?.right
      transform: Translate {
        x: popupDelegate.popupOffset
      }

      NotificationItem {
        id: popupItem

        index: popupDelegate.index
        modelData: popupDelegate.retainedModelData
        isPopup: true
        height: implicitHeight
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
      }

      Connections {
        target: popupDelegate.retainedModelData

        function onIsPopupExitingChanged() {
          if (popupDelegate.retainedModelData.isPopupExiting)
            popupDelegate.startRemoval();
        }
      }
    }

    HoverHandler {
      onHoveredChanged: {
        SNotifications.arePopupsHovered = hovered;
      }
    }

  }
}
