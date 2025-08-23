pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  property PwNode defaultSink: Pipewire.defaultAudioSink
  property PwNode defaultSource: Pipewire.defaultAudioSource
  property bool ready: root.defaultSink?.ready ?? false
  property real volume: root.defaultSink?.audio?.volume ?? 0
  property bool muted: root.defaultSink?.audio?.muted ?? false

  signal sinkProtectionTriggered(string reason)

  PwObjectTracker {
    objects: [root.defaultSink, root.defaultSource]
  }

  // PwObjectTracker {
  //   objects: Pipewire.nodes
  // }

  function getIcon() {
    if (!root.ready) {
      return "audio-volume-off";
    }
    if (root.muted) {
      return "audio-volume-muted";
    }
    const vol = root.volume * 100;
    const icons = [[66, "audio-volume-high"], [33, "audio-volume-medium"], [1, "audio-volume-low"], [0, "audio-volume-low"],];
    const icon = icons.find(([threshold, _]) => vol >= threshold);
    return icon?.[1] ?? "audio-volume-off";
  }
}
