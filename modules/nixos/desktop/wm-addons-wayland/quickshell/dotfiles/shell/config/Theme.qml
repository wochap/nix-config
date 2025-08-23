pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property alias options: jsonAdapter
  property bool ready: false

  FileView {
    path: `${Qt.resolvedUrl(Paths.config)}/theme.json`
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoaded: root.ready = true
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: jsonAdapter

      property string flavour: "mocha"
      property string primary: jsonAdapter.mauve
      property string secondary: jsonAdapter.green
      property string tertiary: jsonAdapter.peach
      property string border: jsonAdapter.surface2
      property string borderSecondary: jsonAdapter.surface0
      property string background: jsonAdapter.base
      property string backgroundOverlay: jsonAdapter.mantle
      property string shadow: jsonAdapter.crust
      property string textDimmed: overlay0
      property string rosewater: "#f5e0dc"
      property string flamingo: "#f2cdcd"
      property string pink: "#f5c2e7"
      property string mauve: "#cba6f7"
      property string red: "#f38ba8"
      property string maroon: "#eba0ac"
      property string peach: "#fab387"
      property string yellow: "#f9e2af"
      property string green: "#a6e3a1"
      property string teal: "#94e2d5"
      property string sky: "#89dceb"
      property string sapphire: "#74c7ec"
      property string blue: "#89b4fa"
      property string lavender: "#b4befe"
      property string text: "#cdd6f4"
      property string subtext1: "#bac2de"
      property string subtext0: "#a6adc8"
      property string overlay2: "#9399b2"
      property string overlay1: "#7f849c"
      property string overlay0: "#6c7086"
      property string surface2: "#585b70"
      property string surface1: "#45475a"
      property string surface0: "#313244"
      property string base: "#1e1e2e"
      property string mantle: "#181825"
      property string crust: "#11111b"
    }
  }
}
