pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property alias options: jsonAdapter
  property bool ready: false
  signal changed

  function addAlpha(hexColor, alpha) {
    // 1. Sanitize the hex color input
    let cleanHex = hexColor.startsWith('#') ? hexColor.slice(1) : hexColor;

    // 2. Validate the hex color
    if (!/^[0-9A-F]{6}$/i.test(cleanHex)) {
      console.error("Invalid hex color format. Please use #RRGGBB.");
      return ""; // Return empty for invalid input
    }

    // 3. Clamp the alpha value to the valid range [0, 1]
    const clampedAlpha = Math.max(0, Math.min(1, alpha));

    // 4. Convert the alpha value (0-1) to a 0-255 integer
    const alpha255 = Math.round(clampedAlpha * 255);

    // 5. Convert the 0-255 integer to a two-digit hexadecimal string
    // .toString(16) converts to hex.
    // .padStart(2, '0') ensures it's always two characters (e.g., 'F' becomes '0F').
    const alphaHex = alpha255.toString(16).padStart(2, '0').toUpperCase();

    // 6. Concatenate the alpha hex with the original color hex
    return `#${alphaHex}${cleanHex}`;
  }

  FileView {
    id: fileView

    path: `${Qt.resolvedUrl(Paths.shellConfig)}/theme.json`
    watchChanges: true
    onLoaded: {
      fileView.reload();
      root.ready = true;
      root.changed();
    }
    onFileChanged: {
      fileView.reload();
      root.changed();
    }
    onLoadFailed: error => {
      // TODO: doesn't work well
      // if (error == FileViewError.FileNotFound) {
      //   fileView.writeAdapter();
      //   root.ready = true;
      // }
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
      property string shadow: "#11111b"
      property string textDimmed: jsonAdapter.overlay0
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
