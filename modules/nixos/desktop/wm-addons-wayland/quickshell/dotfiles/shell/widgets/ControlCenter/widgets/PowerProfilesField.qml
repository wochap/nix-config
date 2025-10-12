pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.ControlCenter.widgets

RowLayout {
  spacing: 0

  ButtonGroup {
    id: powerProfileGroup
    onCheckedButtonChanged: {
      if (checkedButton) {
        SPowerProfiles.set(checkedButton.profileValue);
      }
    }
  }

  Repeater {
    model: SPowerProfiles.list
    delegate: ToolButton {
      required property var modelData
      property string profileValue: modelData.profile

      contentItem: MaterialIcon {
        icon: modelData.icon
        size: 20
        // color: root.fg
        weight: Font.Light
      }
      ButtonGroup.group: powerProfileGroup
      checkable: true
      checked: modelData.profile === SPowerProfiles.active
    }
  }
}
