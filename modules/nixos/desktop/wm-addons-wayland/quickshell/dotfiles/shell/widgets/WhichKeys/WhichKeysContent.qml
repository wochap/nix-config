import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend

  property var shownBindings: []
  property var shownModifiers: []
  property string shownSubmap: ""
  property bool panelVisible: false
  property real fadeOpacity: 0

  function showPanel() {
    root.shownBindings = root.backend.bindings;
    root.shownModifiers = root.backend.heldModifiers;
    root.shownSubmap = root.backend.submap;
    root.panelVisible = true;
    revealTimer.restart();
  }

  function hidePanel() {
    revealTimer.stop();
    root.fadeOpacity = 0;
  }

  readonly property int columns: Math.max(1, Math.floor((width - 2 * ConfigWhichKeys.panelPadding + ConfigWhichKeys.columnSpacing) / (ConfigWhichKeys.minimumCellWidth + ConfigWhichKeys.columnSpacing)))

  screen: backend.screen
  visible: panelVisible
  implicitHeight: content.implicitHeight + ConfigWhichKeys.panelPadding + ConfigWhichKeys.bottomMargin
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  mask: Region {}

  anchors {
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.namespace: "quickshell:which-keys"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Component.onCompleted: {
    if (root.backend.isOpen)
      root.showPanel();
  }

  Connections {
    target: root.backend

    function onBindingsChanged() {
      if (root.backend.isOpen)
        root.shownBindings = root.backend.bindings;
    }

    function onHeldModifiersChanged() {
      if (root.backend.isOpen)
        root.shownModifiers = root.backend.heldModifiers;
    }

    function onSubmapChanged() {
      if (root.backend.isOpen)
        root.shownSubmap = root.backend.submap;
    }

    function onIsOpenChanged() {
      if (root.backend.isOpen)
        root.showPanel();
      else
        root.hidePanel();
    }
  }

  Timer {
    id: revealTimer

    // Give layer-shell two frames to configure the final anchored geometry.
    interval: 34
    onTriggered: root.fadeOpacity = 1
  }

  Behavior on fadeOpacity {
    NumberAnimation {
      duration: 140
      easing.type: Easing.OutCubic
      onFinished: {
        if (root.fadeOpacity === 0)
          root.panelVisible = false;
      }
    }
  }

  ColumnLayout {
    id: content

    opacity: root.fadeOpacity

    anchors {
      fill: parent
      margins: ConfigWhichKeys.panelPadding
      bottomMargin: ConfigWhichKeys.bottomMargin
    }
    spacing: 32

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 16

      StyledText {
        visible: root.shownSubmap.length > 0
        text: root.shownSubmap.toUpperCase()
        color: Theme.options.peach
        font.pixelSize: Styles.font.pixelSize.small * 2
        font.weight: Font.Bold

        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowBlur: 0.75
          shadowColor: Theme.options.shadow
          shadowHorizontalOffset: 1
          shadowVerticalOffset: 1
        }
      }

      Repeater {
        model: root.shownSubmap.length > 0 ? [] : root.shownModifiers

        delegate: RowLayout {
          id: modifierGroup

          required property int index
          required property string modelData
          spacing: 16

          WhichKeysKeycap {
            label: modifierGroup.modelData
            sizeMultiplier: 2
            borderColor: Theme.options.borderSecondary
          }

          StyledText {
            visible: modifierGroup.index < root.shownModifiers.length - 1
            text: "+"
            color: Theme.options.text
            font.pixelSize: Styles.font.pixelSize.small * 2
            font.weight: Font.Bold

            layer.enabled: true
            layer.effect: MultiEffect {
              shadowEnabled: true
              shadowBlur: 0.75
              shadowColor: Theme.options.shadow
              shadowHorizontalOffset: 1
              shadowVerticalOffset: 1
            }
          }
        }
      }
    }

    GridLayout {
      Layout.fillWidth: true
      columns: root.columns
      columnSpacing: ConfigWhichKeys.columnSpacing
      rowSpacing: ConfigWhichKeys.rowSpacing

      Repeater {
        model: root.shownBindings

        delegate: WhichKeysBinding {
          required property var modelData

          Layout.alignment: Qt.AlignLeft
          keycaps: modelData.keycaps
          description: modelData.description
        }
      }
    }
  }
}
