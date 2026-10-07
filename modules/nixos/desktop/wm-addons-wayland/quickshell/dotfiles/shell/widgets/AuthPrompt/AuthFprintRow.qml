import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// fingerprint hint above the password field (polkit only), always two lines
// tall so the dialog never jumps, see design/project/AuthDialog.dc.html
RowLayout {
  id: root

  // idle | scanning | nomatch | matched | off
  property string fpState: "idle"
  // off reason: timeout | exhausted | unenrolled
  property string note: ""
  // PAM text shown as is (swipe sensors, retry hints)
  property string pamText: ""
  property int triesLeft: 0
  property string who: ""

  readonly property bool isScanning: root.fpState === "scanning"
  readonly property bool isMatched: root.fpState === "matched"
  readonly property string noteText: {
    if (root.note === "timeout") {
      return "Verification timed out — use your password";
    }
    if (root.note === "unenrolled") {
      return `No fingerprints enrolled for ${root.who} — use the password`;
    }
    return "Fingerprint unavailable — use your password";
  }
  readonly property string message: {
    switch (root.fpState) {
    case "scanning":
      return root.pamText || "Reading fingerprint…";
    case "nomatch":
      return "Fingerprint not recognized, try again";
    case "matched":
      return "Fingerprint recognized — closing";
    case "off":
      return root.noteText;
    default:
      return root.pamText || "Touch the fingerprint reader or enter your password";
    }
  }
  readonly property string meta: root.fpState === "nomatch" ? ` · ${root.triesLeft} ${root.triesLeft === 1 ? "try" : "tries"} left` : ""

  function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  Layout.minimumHeight: 32
  spacing: 8

  MaterialIcon {
    id: glyph

    Layout.alignment: Qt.AlignVCenter
    icon: root.isMatched ? "check_circle" : "fingerprint"
    size: 16
    fill: 1
    weight: Font.Normal
    color: {
      switch (root.fpState) {
      case "scanning":
        return ConfigAuth.ink;
      case "nomatch":
        return Theme.options.peach;
      case "matched":
        return Theme.options.green;
      case "off":
        return ConfigAuth.placeholder;
      default:
        return ConfigAuth.subtext;
      }
    }

    SequentialAnimation {
      running: root.isScanning
      loops: Animation.Infinite
      onStopped: {
        glyph.opacity = 1;
        glyph.scale = 1;
      }

      ParallelAnimation {
        NumberAnimation {
          target: glyph
          property: "opacity"
          to: 0.45
          duration: 600
          easing.type: Easing.InOutSine
        }
        NumberAnimation {
          target: glyph
          property: "scale"
          to: 0.9
          duration: 600
          easing.type: Easing.InOutSine
        }
      }
      ParallelAnimation {
        NumberAnimation {
          target: glyph
          property: "opacity"
          to: 1
          duration: 600
          easing.type: Easing.InOutSine
        }
        NumberAnimation {
          target: glyph
          property: "scale"
          to: 1
          duration: 600
          easing.type: Easing.InOutSine
        }
      }
    }

    ParallelAnimation {
      id: popAnimation

      NumberAnimation {
        target: glyph
        property: "opacity"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.OutBack
      }
      NumberAnimation {
        target: glyph
        property: "scale"
        from: 0.6
        to: 1
        duration: 200
        easing.type: Easing.OutBack
      }
    }
  }

  StyledText {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    text: `${root.escapeHtml(root.message)}<font color="${ConfigAuth.subtext}">${root.meta}</font>`
    textFormat: Text.StyledText
    color: root.fpState === "idle" || root.fpState === "off" ? ConfigAuth.subtext : Theme.options.text
    wrapMode: Text.Wrap
    maximumLineCount: 2
    elide: Text.ElideRight
    font.pixelSize: ConfigAuth.metaSize
    lineHeight: 16
    lineHeightMode: Text.FixedHeight
  }

  onIsMatchedChanged: {
    if (root.isMatched) {
      popAnimation.restart();
    }
  }
}
