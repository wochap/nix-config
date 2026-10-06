pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.AuthPrompt
import qs.widgets.Lock

// password field + layout badge + status rows, see design/project/LockInput.dc.html
FocusScope {
  id: root

  readonly property string lockState: SLockSession.state
  readonly property string fp: SLockSession.fp
  readonly property bool isWrong: root.lockState === "wrong"
  readonly property bool isMatched: root.fp === "matched"
  readonly property bool isDone: SLockSession.isSuccess || root.isMatched
  readonly property bool showsFingerprint: !SLockSession.isVerifying && !SLockSession.isLockedOut && !root.isDone

  // every key of the field reaches this first, accept it to keep it out
  signal keyPressed(var event)

  function focusInput() {
    field.focusInput();
  }

  implicitWidth: ConfigLock.fieldWidth
  implicitHeight: column.implicitHeight

  component StatusRow: Row {
    id: row

    required property string icon
    required property string text
    property color iconColor: ConfigLock.subtext
    property color textColor: ConfigLock.subtext
    property bool isPulsing: false

    Layout.alignment: Qt.AlignHCenter
    spacing: 8

    MaterialIcon {
      id: glyph

      anchors.verticalCenter: parent.verticalCenter
      icon: row.icon
      size: 16
      fill: 1
      weight: Font.Normal
      color: row.iconColor

      SequentialAnimation {
        running: row.isPulsing
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
    }

    StyledText {
      anchors.verticalCenter: parent.verticalCenter
      text: row.text
      color: row.textColor
      font.pixelSize: Styles.font.pixelSize.small
      lineHeight: 16
      lineHeightMode: Text.FixedHeight
    }
  }

  Connections {
    target: SLockSession

    function onErrorCountChanged() {
      field.clear();
      field.focusInput();
      shakeAnimation.restart();
    }

    function onStateChanged() {
      if (SLockSession.state === "empty") {
        field.clear();
        field.isRevealed = false;
        field.focusInput();
      }
    }
  }

  ColumnLayout {
    id: column

    width: parent.width
    spacing: 12

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: field.implicitHeight

      transform: Translate {
        id: shake
      }

      AuthField {
        id: field

        anchors.fill: parent
        focus: true
        enabled: !SLockSession.isLockedOut
        opacity: SLockSession.isLockedOut ? ConfigLock.disabledOpacity : 1
        ink: ConfigLock.ink
        placeholder: SLockSession.isLockedOut ? "Locked" : "Password"
        leadingIcon: SLockSession.isLockedOut ? "timer" : root.isDone ? "lock_open" : "lock"
        leadingIconColor: root.isDone ? Theme.options.green : ConfigLock.subtext
        isError: root.isWrong
        isSuccess: root.isDone
        hasSuccessRing: true
        isReadOnly: SLockSession.isVerifying || root.isDone
        isBusy: SLockSession.isSpinnerVisible
        hasEye: !SLockSession.isVerifying && !SLockSession.isLockedOut && !root.isDone
        textSize: Styles.font.pixelSize.normal
        hiddenTextSize: Styles.font.pixelSize.normal
        hiddenLetterSpacing: 2
        onAccepted: SLockSession.submit(field.text)
        onTextChanged: {
          SLockSession.setTyping(field.text !== "");
          SLockSession.poke();
        }
        onKeyPressed: event => {
          SLockSession.poke();
          root.keyPressed(event);
        }

        // drains over the lockout, along the bottom edge
        StyledRect {
          anchors {
            left: parent.left
            bottom: parent.bottom
          }
          visible: SLockSession.isLockedOut
          height: 2
          width: parent.width * SLockSession.lockoutRemaining / SLockSession.lockoutSeconds
          color: ConfigLock.ink

          Behavior on width {
            NumberAnimation {
              duration: 1000
            }
          }
        }
      }

      // outside the 360px so the field stays centred
      StyledRect {
        x: parent.width + 8
        y: (parent.height - height) / 2
        visible: SKeyboardLayout.current !== ""
        implicitWidth: layoutText.implicitWidth + 12
        implicitHeight: 20
        radius: Styles.radius.small
        border.width: 1
        border.color: SKeyboardLayout.isDefault ? ConfigLock.fieldBorder : ConfigLock.ink
        color: SKeyboardLayout.isDefault ? "transparent" : Theme.addAlpha(String(ConfigLock.ink), 0.12)

        StyledText {
          id: layoutText

          anchors.centerIn: parent
          text: SKeyboardLayout.current
          color: SKeyboardLayout.isDefault ? ConfigLock.subtext : ConfigLock.ink
          font.pixelSize: Styles.font.pixelSize.smaller
          font.weight: Font.Medium
        }
      }
    }

    // order: result, Caps Lock, fingerprint; rows only grow downward

    StatusRow {
      visible: root.isWrong
      icon: "error"
      text: `Wrong password · ${SLockSession.attemptsLeft} ${SLockSession.attemptsLeft === 1 ? "attempt" : "attempts"} left`
      iconColor: Theme.options.red
      textColor: Theme.options.red
    }

    StatusRow {
      visible: SLockSession.isLockedOut
      icon: "timer"
      text: `Too many attempts · try again in ${Math.floor(SLockSession.lockoutRemaining / 60)}:${String(SLockSession.lockoutRemaining % 60).padStart(2, "0")}`
    }

    StatusRow {
      visible: root.isDone
      icon: "check_circle"
      text: root.isMatched ? "Fingerprint matched" : "Unlocked"
      iconColor: Theme.options.green
      textColor: Theme.options.text
    }

    StatusRow {
      visible: SCapslock.isLock && !SLockSession.isLockedOut && !root.isDone
      icon: "keyboard_capslock"
      text: "Caps Lock is on"
      iconColor: Theme.options.peach
    }

    StatusRow {
      visible: root.showsFingerprint && root.fp === "idle"
      icon: "fingerprint"
      text: "or touch the sensor"
    }

    StatusRow {
      visible: root.showsFingerprint && root.fp === "scanning"
      icon: "fingerprint"
      text: "Reading fingerprint…"
      iconColor: ConfigLock.ink
      isPulsing: visible
    }

    StatusRow {
      visible: root.showsFingerprint && root.fp === "nomatch"
      icon: "fingerprint"
      text: `Not recognized · try again (${SLockSession.fingerprintTriesLeft} left)`
      iconColor: Theme.options.peach
      textColor: Theme.options.peach
    }
  }

  SequentialAnimation {
    id: shakeAnimation

    NumberAnimation {
      target: shake
      property: "x"
      to: -6
      duration: 45
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: shake
      property: "x"
      to: 6
      duration: 45
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: shake
      property: "x"
      to: -4
      duration: 45
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: shake
      property: "x"
      to: 4
      duration: 45
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: shake
      property: "x"
      to: -2
      duration: 45
      easing.type: Easing.OutQuad
    }
    NumberAnimation {
      target: shake
      property: "x"
      to: 0
      duration: 75
      easing.type: Easing.OutQuad
    }
  }
}
