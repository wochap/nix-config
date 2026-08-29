pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string grayScaleFilterName: "grayscale"
  property string oledSaverFilterName: "oled-saver"
  property string readerFilterName: "reader"
  property bool isGrayScaleActive: false
  property bool isOledSaverActive: false
  property bool isReaderActive: false

  function setActiveFilter(filterName) {
    root.isGrayScaleActive = filterName === root.grayScaleFilterName;
    root.isOledSaverActive = filterName === root.oledSaverFilterName;
    root.isReaderActive = filterName === root.readerFilterName;
  }

  function applyFilter(filterName) {
    setActiveFilter(filterName);
    const lua = filterName === ""
      ? 'hl.config({ decoration = { screen_shader = "" } })'
      : `hl.config({ decoration = { screen_shader = os.getenv("HOME") .. "/.config/hypr/shaders/${filterName}.frag" } })`;
    Quickshell.execDetached(["hyprctl", "eval", lua]);
  }

  function disableAll() {
    applyFilter("");
  }

  function enableGrayScale() {
    applyFilter(root.grayScaleFilterName);
  }

  function enableOledSaver() {
    applyFilter(root.oledSaverFilterName);
  }

  function enableReader() {
    applyFilter(root.readerFilterName);
  }

  function toggleGrayScale() {
    if (root.isGrayScaleActive) {
      disableAll();
    } else {
      enableGrayScale();
    }
  }

  function toggleOledSaver() {
    if (root.isOledSaverActive) {
      disableAll();
    } else {
      enableOledSaver();
    }
  }

  function toggleReader() {
    if (root.isReaderActive) {
      disableAll();
    } else {
      enableReader();
    }
  }

  function getState() {
    getStatus.running = true;
  }

  Process {
    id: getStatus

    running: true
    command: ["hyprctl", "getoption", "decoration.screen_shader"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        const shaderPath = statusCollector.text.split("\n")[0].replace(/^str:\s*/, "").trim();
        const basename = shaderPath.split("/").pop().replace(/\.frag$/, "");
        root.setActiveFilter(basename);
      }
    }
  }
}
