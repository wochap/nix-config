pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  property PwNode defaultSink: Pipewire.defaultAudioSink
  property PwNode defaultSource: Pipewire.defaultAudioSource
  property bool outputReady: root.defaultSink?.ready ?? false
  property real outputVolume: root.defaultSink?.audio?.volume ?? 0
  property bool isOutputMuted: root.defaultSink?.audio?.muted ?? false
  property bool inputReady: root.defaultSource?.ready ?? false
  property real inputVolume: root.defaultSource?.audio?.volume ?? 0
  property bool isInputMuted: root.defaultSource?.audio?.muted ?? false

  signal sinkProtectionTriggered(string reason)

  PwObjectTracker {
    objects: [root.defaultSink, root.defaultSource]
  }

  // PwObjectTracker {
  //   objects: Pipewire.nodes
  // }

  function getOutputIcon() {
    if (!root.outputReady) {
      return "audio-volume-off";
    }
    if (root.isOutputMuted) {
      return "audio-volume-muted";
    }
    const vol = root.outputVolume * 100;
    const icons = [[66, "audio-volume-high"], [33, "audio-volume-medium"], [1, "audio-volume-low"], [0, "audio-volume-low"],];
    const icon = icons.find(([threshold, _]) => vol >= threshold);
    return icon?.[1] ?? "audio-volume-off";
  }

  function getInputIcon() {
    if (!root.inputReady) {
      return "microphone-sensitivity-muted";
    }
    if (root.isInputMuted) {
      return "microphone-sensitivity-muted";
    }
    const vol = root.inputVolume * 100;
    const icons = [[66, "microphone-sensitivity-high"], [33, "microphone-sensitivity-medium"], [1, "microphone-sensitivity-low"], [0, "microphone-sensitivity-low"],];
    const icon = icons.find(([threshold, _]) => vol >= threshold);
    return icon?.[1] ?? "microphone-sensitivity-muted";
  }
}
