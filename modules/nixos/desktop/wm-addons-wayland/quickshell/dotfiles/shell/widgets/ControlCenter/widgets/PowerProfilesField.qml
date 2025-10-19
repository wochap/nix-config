pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.ControlCenter.widgets

RowLayout {
  spacing: 4

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

      // ToolTip.visible: hovered
      // ToolTip.text: modelData.profile
      Layout.fillWidth: true
      ButtonGroup.group: powerProfileGroup
      checkable: true
      checked: modelData.profile === SPowerProfiles.active
      padding: 0
      contentItem: Item {
        MaterialIcon {
          anchors.centerIn: parent
          icon: modelData.icon
          size: 20
          color: {
            if (parent.parent.checked || parent.parent.hovered) {
              return Theme.options.background;
            }
            return Theme.options.text;
          }
          weight: Font.Light
        }
      }
      background: StyledRect {
        implicitWidth: 1
        implicitHeight: 32
        radius: Styles.radius.full
        color: {
          if (parent.hovered) {
            return Qt.lighter(Theme.options.primary, 1.1);
          }
          if (parent.checked) {
            return Theme.options.primary;
          }
          return Theme.options.surface1;
        }
      }
    }
  }
}
