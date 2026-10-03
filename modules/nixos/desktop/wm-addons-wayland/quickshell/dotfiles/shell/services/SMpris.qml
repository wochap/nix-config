pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  readonly property var players: Mpris.players.values
  // prefer whatever is playing, then anything that can be controlled
  readonly property MprisPlayer player: root.players.find(p => p.isPlaying) ?? root.players.find(p => p.canControl) ?? root.players[0] ?? null
  readonly property bool available: root.player !== null

  function formatTime(seconds) {
    const total = Math.max(0, Math.floor(seconds || 0));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const secs = String(total % 60).padStart(2, "0");
    if (hours > 0) {
      return `${hours}:${String(minutes).padStart(2, "0")}:${secs}`;
    }
    return `${minutes}:${secs}`;
  }

  // MprisPlayer.position is not pushed by the player, poll it while playing
  Timer {
    running: root.player?.isPlaying ?? false
    interval: 1000
    repeat: true
    onTriggered: root.player.positionChanged()
  }
}
