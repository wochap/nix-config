import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config
import qs.Woints
import "../Utils.js" as Utils

Button {
  id: root

  required property int index
  required property var clients
  required property var workspace
  required property bool isOccupied
  required property HyprlandMonitor hyprlandMonitor
  property int workspaceId: SHyprland.wsOffset + index + 1
  property bool isFocused: hyprlandMonitor?.activeWorkspace?.id === workspaceId
  property var representativeClient: root.clients.find(client => client.address === root.workspace?.lastwindow) ?? root.clients[0] ?? null
  property bool hasRepresentativeClient: !!root.representativeClient
  // focused workspaces with windows show a taskbar instead of the number
  readonly property bool isExpanded: root.isFocused && root.clients.length > 0
  property real expandProgress: root.isExpanded ? 1 : 0

  // same timing as the control center, expanding is the enter, collapsing the exit
  Behavior on expandProgress {
    id: expandBehavior

    // targetValue is set before the animation starts, isExpanded may not be re-evaluated yet
    NumberAnimation {
      duration: expandBehavior.targetValue > 0 ? Styles.animation.duration : Styles.animation.exitDuration
      easing.type: expandBehavior.targetValue > 0 ? Styles.animation.easingType : Styles.animation.exitEasingType
    }
  }

  Accessible.name: `Workspace ${root.workspaceId}`
  Accessible.checkable: true
  Accessible.checked: root.isFocused
  onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceId}, on_current_monitor = true })`)
  verticalPadding: 0
  horizontalPadding: Utils.lerp(6, 3, root.expandProgress)
  // the background lives in HyprWorkspaces so the focus indicator can slide between workspaces
  background: Item {}
  contentItem: Item {
    id: content

    readonly property real progress: root.expandProgress
    // the other clients unfold once the representative icon is partway grown
    readonly property real othersProgress: Math.max(0, (content.progress - 0.3) / 0.7)
    readonly property real collapsedIconSize: Styles.font.pixelSize.normal
    readonly property real expandedIconSize: 28
    // collapsed layout stacks the icon above the number, overlapping them a bit
    readonly property real overlap: Styles.font.pixelSize.small / 2
    readonly property real collapsedHeight: root.hasRepresentativeClient ? collapsedIconSize - overlap + numberText.implicitHeight : numberText.implicitHeight
    // matches the old ColumnLayout, which split the leftover height between the icon and number cells
    readonly property real collapsedExtra: Math.max(0, content.height - content.collapsedHeight)
    readonly property real collapsedTop: root.hasRepresentativeClient ? content.collapsedExtra / 4 : content.collapsedExtra / 2

    // last non-empty taskbar width, so closing the last window shrinks from it
    // instead of jumping to the number width
    property real lastIconsWidth: 0

    implicitWidth: Math.max(icons.implicitWidth, numberText.implicitWidth, root.clients.length === 0 ? Utils.lerp(numberText.implicitWidth, content.lastIconsWidth, content.progress) : 0)

    Connections {
      target: icons

      function onImplicitWidthChanged() {
        if (icons.implicitWidth > 0) {
          content.lastIconsWidth = icons.implicitWidth;
        }
      }
    }
    implicitHeight: Math.max(content.collapsedHeight, content.expandedIconSize)

    Row {
      id: icons

      anchors.horizontalCenter: parent.horizontalCenter
      y: Utils.lerp(content.collapsedTop, (content.height - icons.height) / 2, content.progress)
      spacing: 1.5 * content.othersProgress

      Repeater {
        model: root.clients

        // morphs from the small workspace icon (only the representative client)
        // to the full size taskbar icon, the other clients grow from nothing after it
        delegate: Item {
          id: client

          readonly property bool isRepresentative: modelData.address === root.representativeClient?.address
          readonly property real progress: client.isRepresentative ? content.progress : content.othersProgress
          readonly property real expandedOpacity: modelData.isFocused ? 1 : 0.5

          width: Utils.lerp(client.isRepresentative ? content.collapsedIconSize : 0, content.expandedIconSize, client.progress)
          height: client.width
          opacity: Utils.lerp(client.isRepresentative ? 1 : 0, client.expandedOpacity, client.progress)
          visible: client.width > 0

          // render at full size and scale down, resizing the icon would reload it every frame
          SystemIcon {
            anchors.centerIn: parent
            icon: modelData.customClass
            size: content.expandedIconSize
            scale: client.width / content.expandedIconSize
            layer.enabled: modelData.floating
            layer.effect: MultiEffect {
              shadowEnabled: true
              shadowBlur: 0.25
              shadowColor: Theme.options.primary
            }
          }

          MouseArea {
            id: clientMouseArea

            readonly property string label: modelData.title || modelData.class

            // temporarily force cursor.no_warps so focusing doesn't move the cursor
            function focusClient() {
              const window = `"address:${modelData.address}"`;
              const raise = modelData.floating ? `hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = ${window} }))` : "";
              Quickshell.execDetached(["hyprctl", "eval", `
                local no_warps = hl.get_config("cursor.no_warps")
                hl.config({ cursor = { no_warps = true } })
                hl.dispatch(hl.dsp.focus({ window = ${window} }))
                ${raise}
                hl.config({ cursor = { no_warps = no_warps } })
              `]);
            }

            anchors.fill: parent
            // collapsed clicks fall through to the workspace button
            enabled: root.isExpanded
            onClicked: clientMouseArea.focusClient()
            Accessible.role: Accessible.Button
            Accessible.name: clientMouseArea.label
            Accessible.checkable: true
            Accessible.checked: modelData.isFocused
            Accessible.onPressAction: clientMouseArea.focusClient()

            Hintable {
              label: clientMouseArea.label
              onActivated: clientMouseArea.focusClient()
            }
          }
        }
      }
    }

    StyledText {
      id: numberText

      anchors.horizontalCenter: parent.horizontalCenter
      y: content.collapsedTop + (root.hasRepresentativeClient ? content.collapsedIconSize - content.overlap + content.collapsedExtra / 2 : 0)
      opacity: 1 - content.progress
      scale: 1 - 0.4 * content.progress
      visible: opacity > 0
      color: root.isFocused && root.isOccupied ? Theme.options.primary : (root.isOccupied ? Theme.options.text : Theme.options.textDimmed)
      text: workspaceId
      font.pixelSize: root.hasRepresentativeClient ? Styles.font.pixelSize.smaller : Styles.font.pixelSize.normal
    }
  }

  Hintable {
    target: root
    label: root.Accessible.name
    onActivated: root.clicked()
  }
}
