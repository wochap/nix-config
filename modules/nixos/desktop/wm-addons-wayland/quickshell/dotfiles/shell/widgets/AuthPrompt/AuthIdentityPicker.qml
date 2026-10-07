pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// polkit "Authenticate as" combo, the popup overlays the content below it
FocusScope {
  id: root

  // [{ name, detail }]
  property var identities: []
  property int selectedIndex: 0
  property bool isOpen: false
  property int highlightedIndex: 0

  signal selected(int index)

  function open() {
    root.highlightedIndex = root.selectedIndex;
    root.isOpen = true;
  }

  function pick(index) {
    root.isOpen = false;
    if (index !== root.selectedIndex) {
      root.selected(index);
    }
  }

  implicitHeight: column.implicitHeight
  activeFocusOnTab: root.enabled
  z: root.isOpen ? 10 : 0
  Accessible.role: Accessible.ComboBox
  Accessible.name: "Authenticate as"
  Accessible.description: root.identities[root.selectedIndex]?.name ?? ""
  Accessible.onPressAction: {
    if (root.isOpen) {
      root.isOpen = false;
    } else {
      root.open();
    }
  }

  onActiveFocusChanged: {
    if (!root.activeFocus) {
      root.isOpen = false;
    }
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
      if (!root.isOpen) {
        root.open();
      } else {
        const step = event.key === Qt.Key_Down ? 1 : -1;
        root.highlightedIndex = (root.highlightedIndex + step + root.identities.length) % root.identities.length;
      }
      event.accepted = true;
    } else if (root.isOpen && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
      root.pick(root.highlightedIndex);
      event.accepted = true;
    } else if (root.isOpen && event.key === Qt.Key_Escape) {
      root.isOpen = false;
      event.accepted = true;
    } else if (!root.isOpen && event.key === Qt.Key_Space) {
      root.open();
      event.accepted = true;
    }
  }

  component Avatar: StyledRect {
    id: avatar

    required property string name

    implicitWidth: 22
    implicitHeight: 22
    radius: width / 2
    color: Theme.options.surface0

    StyledText {
      anchors.centerIn: parent
      text: avatar.name.charAt(0)
      font.pixelSize: ConfigAuth.keycapSize
      font.weight: Font.DemiBold
    }
  }

  ColumnLayout {
    id: column

    anchors {
      left: parent.left
      right: parent.right
    }
    spacing: 6

    StyledText {
      text: "Authenticate as"
      color: ConfigAuth.subtext
      font.pixelSize: ConfigAuth.metaSize
      font.weight: Font.Medium
    }

    Item {
      id: box

      Layout.fillWidth: true
      Layout.preferredHeight: ConfigAuth.fieldHeight

      StyledRect {
        anchors {
          fill: parent
          margins: -1
        }
        visible: root.activeFocus
        radius: ConfigAuth.controlRadius + 1
        border.width: 1
        border.color: ConfigAuth.ink
      }

      StyledRect {
        anchors.fill: parent
        radius: ConfigAuth.controlRadius
        color: Theme.options.mantle
        border.width: 1
        border.color: root.activeFocus ? ConfigAuth.ink : ConfigAuth.fieldBorder
      }

      RowLayout {
        anchors {
          fill: parent
          leftMargin: 8
          rightMargin: 8
        }
        spacing: 8

        Avatar {
          name: root.identities[root.selectedIndex]?.name ?? ""
        }

        StyledText {
          text: root.identities[root.selectedIndex]?.name ?? ""
          font.pixelSize: ConfigAuth.bodySize
          font.weight: Font.Medium
        }

        StyledText {
          Layout.fillWidth: true
          text: root.identities[root.selectedIndex]?.detail ?? ""
          color: ConfigAuth.subtext
          elide: Text.ElideRight
          font.pixelSize: ConfigAuth.metaSize
        }

        MaterialIcon {
          icon: root.isOpen ? "expand_less" : "expand_more"
          size: 20
          color: ConfigAuth.subtext
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.forceActiveFocus();
          if (root.isOpen) {
            root.isOpen = false;
          } else {
            root.open();
          }
        }
      }
    }
  }

  StyledRectangularShadow {
    target: popup
    visible: popup.visible
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: popup

    anchors {
      top: parent.bottom
      topMargin: 4
      left: parent.left
      right: parent.right
    }
    visible: root.isOpen
    height: list.implicitHeight + 8
    radius: ConfigAuth.controlRadius
    color: Theme.options.base
    border.width: 1
    border.color: Theme.options.surface1

    Column {
      id: list

      anchors {
        fill: parent
        margins: 4
      }

      Repeater {
        model: root.identities

        StyledRect {
          id: option

          required property var modelData
          required property int index
          readonly property bool isHighlighted: optionMouseArea.containsMouse || root.highlightedIndex === option.index

          width: list.width
          height: 32
          radius: ConfigAuth.chipRadius
          Accessible.role: Accessible.ListItem
          Accessible.name: option.modelData.name
          Accessible.description: option.modelData.detail
          Accessible.selectable: true
          Accessible.selected: option.index === root.selectedIndex
          Accessible.onPressAction: root.pick(option.index)
          color: option.isHighlighted ? Theme.options.surface0 : "transparent"

          RowLayout {
            anchors {
              fill: parent
              leftMargin: 8
              rightMargin: 8
            }
            spacing: 8

            Avatar {
              name: option.modelData.name
              color: option.isHighlighted ? Theme.options.surface1 : Theme.options.surface0
            }

            StyledText {
              text: option.modelData.name
              font.pixelSize: ConfigAuth.bodySize
              font.weight: Font.Medium
            }

            StyledText {
              Layout.fillWidth: true
              text: option.modelData.detail
              color: ConfigAuth.subtext
              elide: Text.ElideRight
              font.pixelSize: ConfigAuth.metaSize
            }

            MaterialIcon {
              visible: option.index === root.selectedIndex
              icon: "check"
              size: 18
              color: ConfigAuth.ink
            }
          }

          MouseArea {
            id: optionMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pick(option.index)
          }
        }
      }
    }
  }
}
