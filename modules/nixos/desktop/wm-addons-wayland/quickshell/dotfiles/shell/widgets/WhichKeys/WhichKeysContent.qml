import Quickshell
import Quickshell.Wayland
import QtQuick
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
  // read by qs.Woints SHints, the attached WlrLayershell is not reachable from JS
  readonly property string namespace: WlrLayershell.namespace
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

  // same timing as the control center: enter 150ms OutCubic, exit 120ms InCubic
  Behavior on fadeOpacity {
    NumberAnimation {
      duration: root.backend.isOpen ? Styles.animation.duration : Styles.animation.exitDuration
      easing.type: root.backend.isOpen ? Styles.animation.easingType : Styles.animation.exitEasingType
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

      Rectangle {
        id: submapPill

        visible: root.shownSubmap.length > 0
        implicitWidth: submapLabel.implicitWidth + 24
        implicitHeight: submapLabel.implicitHeight + 8
        radius: 8
        color: "transparent"

        StyledRectangularShadow {
          target: submapPill
          z: -1
          blur: 8
          spread: 1
          cached: false
        }

        StyledText {
          id: submapLabel

          anchors.centerIn: parent
          text: root.shownSubmap.toUpperCase()
          color: Theme.options.peach
          font.pixelSize: Styles.font.pixelSize.small * 2
          font.weight: Font.Bold
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

          Rectangle {
            id: plusPill

            visible: modifierGroup.index < root.shownModifiers.length - 1
            implicitWidth: plusLabel.implicitWidth + 24
            implicitHeight: plusLabel.implicitHeight + 8
            radius: 8
            color: "transparent"

            StyledRectangularShadow {
              target: plusPill
              z: -1
              blur: 8
              spread: 1
              cached: false
            }

            StyledText {
              id: plusLabel

              anchors.centerIn: parent
              text: "+"
              color: Theme.options.text
              font.pixelSize: Styles.font.pixelSize.small * 2
              font.weight: Font.Bold
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
