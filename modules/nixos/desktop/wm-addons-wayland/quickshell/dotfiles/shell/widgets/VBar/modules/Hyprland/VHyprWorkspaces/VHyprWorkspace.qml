import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config
import qs.Woints
import "../../../../common/HyprUtils.js" as Utils

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
  // focused workspaces with windows show a vertical taskbar instead of just the number
  readonly property bool isExpanded: root.isFocused && root.clients.length > 0
  property real expandProgress: root.isExpanded ? 1 : 0

  Behavior on expandProgress {
    id: expandBehavior

    NumberAnimation {
      duration: expandBehavior.targetValue > 0 ? Styles.animation.duration : Styles.animation.exitDuration
      easing.type: expandBehavior.targetValue > 0 ? Styles.animation.easingType : Styles.animation.exitEasingType
    }
  }

  Accessible.name: `Workspace ${root.workspaceId}`
  Accessible.checkable: true
  Accessible.checked: root.isFocused
  onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceId}, on_current_monitor = true })`)
  verticalPadding: 2
  horizontalPadding: 2
  background: Item {}

  implicitWidth: 36

  contentItem: Item {
    id: content

    readonly property real progress: root.expandProgress
    readonly property real othersProgress: Math.max(0, (content.progress - 0.3) / 0.7)
    readonly property real collapsedIconSize: Styles.font.pixelSize.normal
    readonly property real expandedIconSize: 28
    readonly property real collapsedHeight: root.hasRepresentativeClient ? 36 : 24
    readonly property real expandedHeight: 8 + root.clients.length * expandedIconSize + Math.max(0, root.clients.length - 1) * (4 * content.othersProgress)

    implicitWidth: 36
    implicitHeight: Math.max(content.collapsedHeight, Utils.lerp(content.collapsedHeight, content.expandedHeight, content.progress))

    Column {
      id: icons

      anchors.horizontalCenter: parent.horizontalCenter
      y: 4
      spacing: 4 * content.othersProgress

      Repeater {
        model: root.clients

        delegate: Item {
          id: client

          readonly property bool isRepresentative: modelData.address === root.representativeClient?.address
          readonly property real progress: client.isRepresentative ? content.progress : content.othersProgress
          readonly property real expandedOpacity: modelData.isFocused ? 1 : 0.55

          width: Utils.lerp(client.isRepresentative ? content.collapsedIconSize : 0, content.expandedIconSize, client.progress)
          height: client.width
          opacity: Utils.lerp(client.isRepresentative ? 1 : 0, client.expandedOpacity, client.progress)
          visible: client.width > 0
          anchors.horizontalCenter: icons.horizontalCenter

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
            enabled: root.isExpanded
            onClicked: {
              tooltip.shown = false;
              clientMouseArea.focusClient();
            }
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

          HoverHandler {
            id: hoverHandler

            onHoveredChanged: {
              if (hovered) {
                tooltipTimer.restart();
              } else {
                tooltipTimer.stop();
                tooltip.shown = false;
              }
            }
          }

          Timer {
            id: tooltipTimer

            interval: 350
            onTriggered: tooltip.shown = ((modelData.title ?? "") || (modelData.class ?? "")).length > 0
          }

          WindowTooltip {
            id: tooltip

            readonly property real clientRight: client.mapToItem(null, client.width, 0).x

            anchor.item: client
            anchor.edges: Edges.Right | Edges.Top
            anchor.gravity: Edges.Right | Edges.Bottom
            anchor.margins.right: Math.round(tooltip.clientRight - 34)
            anchor.margins.top: -(Math.round((tooltip.bubbleHeight - client.height) / 2) + 12)
            icon: modelData.customClass || Utils.mapAppId(modelData.class ?? "")
            appId: modelData.class ?? ""
            title: modelData.title ?? ""
          }
        }
      }
    }

    StyledText {
      id: numberText

      anchors.horizontalCenter: parent.horizontalCenter
      y: root.hasRepresentativeClient ? 21 : Math.round((content.height - numberText.implicitHeight) / 2)
      opacity: 1 - content.progress
      scale: 1 - 0.3 * content.progress
      visible: opacity > 0
      color: root.isFocused && root.isOccupied ? Theme.options.primary : (root.isOccupied ? Theme.options.text : Theme.options.textDimmed)
      text: root.workspaceId.toString()
      font.pixelSize: root.hasRepresentativeClient ? Styles.font.pixelSize.smaller : Styles.font.pixelSize.normal
    }
  }

  Hintable {
    target: root
    label: root.Accessible.name
    onActivated: root.clicked()
  }
}
