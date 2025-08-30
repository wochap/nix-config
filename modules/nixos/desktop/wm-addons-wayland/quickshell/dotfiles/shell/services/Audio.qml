pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.config

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
  property string outputIcon: "audio-volume-muted"
  property string outputIconColor: Theme.options.text
  property string inputIcon: "microphone-sensitivity-muted"
  property string inputIconColor: Theme.options.text

  signal sinkProtectionTriggered(string reason)

  PwObjectTracker {
    objects: [root.defaultSink, root.defaultSource]
  }

  Component.onCompleted: {
    root.updateOutputIcon();
    root.updateInputIcon();
  }

  onOutputReadyChanged: {
    root.updateOutputIcon();
  }
  onIsOutputMutedChanged: {
    root.updateOutputIcon();
  }
  onOutputVolumeChanged: {
    root.updateOutputIcon();
  }

  onInputReadyChanged: {
    root.updateInputIcon();
  }
  onIsInputMutedChanged: {
    root.updateInputIcon();
  }
  onInputVolumeChanged: {
    root.updateInputIcon();
  }

  function updateOutputIcon() {
    if (!root.outputReady) {
      root.outputIcon = "audio-volume-off";
      root.outputIconColor = Theme.options.textDimmed;
      return;
    }
    if (root.isOutputMuted) {
      root.outputIcon = "audio-volume-muted";
      root.outputIconColor = Theme.options.red;
      return;
    }
    const vol = root.outputVolume * 100;
    const icons = [[66, "audio-volume-high"], [33, "audio-volume-medium"], [1, "audio-volume-low"], [0, "audio-volume-low"],];
    const icon = icons.find(([threshold, _]) => vol >= threshold);
    root.outputIcon = icon?.[1] ?? "audio-volume-off";
    root.outputIconColor = Theme.options.text;
  }

  function updateInputIcon() {
    if (!root.inputReady) {
      root.inputIcon = "microphone-sensitivity-muted";
      root.inputIconColor = Theme.options.textDimmed;
      return;
    }
    if (root.isInputMuted) {
      root.inputIcon = "microphone-sensitivity-muted";
      root.inputIconColor = Theme.options.red;
      return;
    }
    const vol = root.inputVolume * 100;
    const icons = [[66, "microphone-sensitivity-high"], [33, "microphone-sensitivity-medium"], [1, "microphone-sensitivity-low"], [0, "microphone-sensitivity-low"],];
    const icon = icons.find(([threshold, _]) => vol >= threshold);
    root.inputIcon = icon?.[1] ?? "microphone-sensitivity-muted";
    root.inputIconColor = Theme.options.text;
  }
}
