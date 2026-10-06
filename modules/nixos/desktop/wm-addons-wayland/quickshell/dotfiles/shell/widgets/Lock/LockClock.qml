import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Lock

// clock + date, see design/project/LockClock.dc.html
ColumnLayout {
  id: root

  // secondary output: "Unlock on the other screen" with an arrow
  property bool isHintVisible: false
  property string hintIcon: "arrow_back"
  property date now: new Date()

  spacing: 4

  // monotonic timers stall during suspend, catch up when the lock shows
  Connections {
    target: SLockSession

    function onIsLockedChanged() {
      root.now = new Date();
    }
  }

  // re-armed on each minute boundary, no per-second polling
  Timer {
    running: true
    repeat: true
    interval: (60 - root.now.getSeconds()) * 1000 - root.now.getMilliseconds() + 50
    onTriggered: root.now = new Date()
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter
    text: Qt.formatTime(root.now, "HH:mm")
    font.pixelSize: ConfigLock.clockSize
    font.weight: Font.Medium
    font.letterSpacing: -ConfigLock.clockSize * 0.02
    font.features: {
      "tnum": 1
    }
    lineHeight: ConfigLock.clockSize
    lineHeightMode: Text.FixedHeight
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter
    text: Qt.formatDate(root.now, "dddd, d MMMM yyyy")
    color: ConfigLock.subtext
    font.pixelSize: ConfigLock.dateSize
    lineHeight: 28
    lineHeightMode: Text.FixedHeight
  }

  RowLayout {
    id: hint

    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 20 - root.spacing
    spacing: 6
    opacity: root.isHintVisible ? 1 : 0

    transform: Translate {
      y: root.isHintVisible ? 0 : Styles.animation.slideDistance

      Behavior on y {
        NumberAnimation {
          duration: root.isHintVisible ? Styles.animation.duration : Styles.animation.exitDuration
          easing.type: root.isHintVisible ? Styles.animation.easingType : Styles.animation.exitEasingType
        }
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: root.isHintVisible ? Styles.animation.duration : Styles.animation.exitDuration
        easing.type: root.isHintVisible ? Styles.animation.easingType : Styles.animation.exitEasingType
      }
    }

    MaterialIcon {
      icon: root.hintIcon
      size: 16
      weight: Font.Normal
      color: ConfigLock.subtext
    }

    StyledText {
      text: "Unlock on the other screen"
      color: ConfigLock.subtext
      font.pixelSize: Styles.font.pixelSize.small
    }
  }
}
