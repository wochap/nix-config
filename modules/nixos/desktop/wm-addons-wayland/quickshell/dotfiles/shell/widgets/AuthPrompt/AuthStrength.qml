import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// 4 segment strength meter for new passwords
RowLayout {
  id: root

  property string password: ""
  // 0..4
  readonly property int score: {
    const p = root.password;
    if (p.length === 0) {
      return 0;
    }
    let score = 0;
    if (p.length >= 8) {
      score++;
    }
    if (p.length >= 12) {
      score++;
    }
    if (/[a-z]/.test(p) && /[A-Z]/.test(p) && /[0-9]/.test(p)) {
      score++;
    }
    if (/[^A-Za-z0-9]/.test(p)) {
      score++;
    }
    return Math.max(1, score);
  }
  readonly property var _labels: ["Empty", "Weak", "Fair", "Good", "Strong"]

  spacing: 12

  RowLayout {
    Layout.fillWidth: true
    spacing: 4

    Repeater {
      model: 4

      StyledRect {
        required property int index

        Layout.fillWidth: true
        Layout.preferredHeight: 4
        radius: 2
        color: index < root.score ? Theme.options.green : Theme.options.surface0
      }
    }
  }

  StyledText {
    text: `${root._labels[root.score]} · ${root.password.length} characters`
    color: ConfigAuth.subtext
    font.pixelSize: ConfigAuth.metaSize
  }
}
