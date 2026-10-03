import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.ControlCenter

RowLayout {
  id: root

  spacing: 10

  StyledRect {
    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    radius: width / 2
    color: Theme.options.surface0
    border {
      width: 1
      color: Theme.options.surface1
    }

    SystemIcon {
      enableColoriser: true
      anchors.centerIn: parent
      icon: "avatar-default-symbolic"
      size: Styles.font.pixelSize.hugeass
      color: Theme.options.primary
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 0

    StyledText {
      Layout.fillWidth: true
      text: `${SSystemInfo.user}@${SSystemInfo.host}`
      elide: Text.ElideRight
      font.pixelSize: Styles.font.pixelSize.normal
      font.weight: Font.Medium
    }

    StyledText {
      Layout.fillWidth: true
      text: `up ${SSystemInfo.uptime}${SSystemInfo.hyprlandVersion ? ` · Hyprland ${SSystemInfo.hyprlandVersion}` : ""}`
      elide: Text.ElideRight
      font.pixelSize: Styles.font.pixelSize.smaller
      color: Theme.options.subtext0
    }
  }

  RowLayout {
    id: buttons

    // only one destructive button armed at a time
    function disarmOthers(button) {
      for (const child of buttons.children) {
        if (child !== button && child.disarm) {
          child.disarm();
        }
      }
    }

    spacing: 4

    HeaderButton {
      icon: "system-lock-screen"
      tooltip: "Lock"
      onActivated: SControlCenter.runSessionAction("lock")
    }

    HeaderButton {
      icon: "system-suspend"
      tooltip: "Suspend"
      onActivated: SControlCenter.runSessionAction("suspend")
    }

    HeaderButton {
      id: logoutButton

      icon: "system-log-out"
      tooltip: "Log out"
      needsConfirm: true
      onArmed: buttons.disarmOthers(logoutButton)
      onActivated: SControlCenter.runSessionAction("logout")
    }

    HeaderButton {
      id: rebootButton

      icon: "system-reboot"
      tooltip: "Reboot"
      needsConfirm: true
      onArmed: buttons.disarmOthers(rebootButton)
      onActivated: SControlCenter.runSessionAction("reboot")
    }

    HeaderButton {
      id: powerButton

      icon: "system-shutdown"
      tooltip: "Power off"
      isDestructive: true
      needsConfirm: true
      onArmed: buttons.disarmOthers(powerButton)
      onActivated: SControlCenter.runSessionAction("poweroff")
    }
  }
}
