pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.AuthPrompt

// one dialog for polkit, gpg-agent, ssh and gnome-keyring prompts,
// see design/project/AuthDialog.dc.html
FocusScope {
  id: root

  readonly property var request: SAuth.current
  readonly property int requestUid: root.request?.uid ?? 0
  readonly property string mode: root.request?.mode ?? "password"
  readonly property bool isNewPassword: root.mode === "new-password"
  readonly property bool hasInput: root.mode === "password" || root.isNewPassword
  readonly property bool isVerifying: SAuth.state === "verifying"
  readonly property bool isError: SAuth.state === "error"
  readonly property bool isSuccess: SAuth.state === "success"
  readonly property bool isLocked: root.isVerifying || root.isSuccess
  readonly property bool isPolkit: root.request?.source === "polkit"
  readonly property var identities: root.request?.identities ?? []
  readonly property bool doPasswordsMatch: confirmField.text !== "" && confirmField.text === passwordField.text
  readonly property bool canSubmit: !root.isLocked && (!root.isNewPassword || root.doPasswordsMatch)
  property bool isChoiceChecked: false
  property bool isSpinnerVisible: false
  property real remainingSeconds: 0

  function submit() {
    if (!root.canSubmit) {
      return;
    }
    if (root.mode === "notice") {
      return;
    }
    SAuth.respond("ok", root.hasInput ? passwordField.text : "", root.isChoiceChecked, strength.score);
  }

  function cancel() {
    if (root.isSuccess) {
      return;
    }
    SAuth.respond("cancel");
  }

  function focusDefault() {
    if (root.hasInput) {
      passwordField.focusInput();
    } else if (primaryButton.visible) {
      primaryButton.forceActiveFocus();
    } else {
      root.forceActiveFocus();
    }
  }

  function reset() {
    passwordField.clear();
    confirmField.clear();
    passwordField.isRevealed = root.request?.isResponseVisible ?? false;
    confirmField.isRevealed = false;
    root.isChoiceChecked = root.request?.choice?.checked ?? false;
    root.remainingSeconds = root.request?.timeout ?? 0;
    Qt.callLater(root.focusDefault);
  }

  implicitWidth: ConfigAuth.dialogWidth
  implicitHeight: card.height
  focus: true

  // a new request replaces the content, a retry of the same one keeps it
  onRequestUidChanged: root.reset()
  Component.onCompleted: root.reset()
  Component.onDestruction: {
    passwordField.clear();
    confirmField.clear();
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Escape) {
      root.cancel();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.submit();
      event.accepted = true;
    }
  }

  Connections {
    target: SAuth

    function onErrorCountChanged() {
      passwordField.clear();
      confirmField.clear();
      // every retry is a fresh prompt for the requester, its timeout restarts
      root.remainingSeconds = root.request?.timeout ?? 0;
      root.focusDefault();
      shakeAnimation.restart();
    }

    function onStateChanged() {
      root.isSpinnerVisible = false;
      if (SAuth.state === "verifying") {
        spinnerTimer.restart();
      } else if (SAuth.state === "default" || SAuth.state === "error") {
        root.focusDefault();
      }
    }
  }

  Timer {
    id: spinnerTimer

    interval: ConfigAuth.spinnerDelay
    onTriggered: root.isSpinnerVisible = root.isVerifying
  }

  Timer {
    id: countdownTimer

    interval: 1000
    repeat: true
    running: root.remainingSeconds > 0 && !root.isLocked
    onTriggered: {
      root.remainingSeconds = Math.max(0, root.remainingSeconds - 1);
      if (root.remainingSeconds === 0) {
        SAuth.respond("timeout");
      }
    }
  }

  transform: Translate {
    id: shake
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

  StyledRectangularShadow {
    target: card
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: card

    width: ConfigAuth.dialogWidth
    height: content.implicitHeight
    radius: ConfigAuth.dialogRadius
    color: Theme.options.base

    // swallow clicks so they don't reach the scrim
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: content

      anchors {
        left: parent.left
        right: parent.right
      }
      spacing: 0

      // header: badge + title + lock · source + phrase
      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: ConfigAuth.dialogPadding
        Layout.leftMargin: ConfigAuth.dialogPadding
        Layout.rightMargin: ConfigAuth.dialogPadding
        spacing: 12

        StyledRect {
          readonly property color tintColor: root.isSuccess ? Theme.options.green : ConfigAuth.tint(root.request?.tint ?? "peach")

          Layout.preferredWidth: ConfigAuth.badgeSize
          Layout.preferredHeight: ConfigAuth.badgeSize
          radius: ConfigAuth.controlRadius
          color: Theme.addAlpha(String(tintColor), ConfigAuth.badgeTint)

          MaterialIcon {
            anchors.centerIn: parent
            icon: root.isSuccess ? "check_circle" : (root.request?.icon ?? "lock")
            size: 20
            fill: 1
            weight: Font.Normal
            color: parent.tintColor
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          StyledText {
            Layout.fillWidth: true
            text: root.request?.title ?? ""
            elide: Text.ElideRight
            font.pixelSize: ConfigAuth.titleSize
            font.weight: Font.DemiBold
          }

          RowLayout {
            spacing: 4

            MaterialIcon {
              icon: "lock"
              size: 14
              fill: 1
              weight: Font.Normal
              color: ConfigAuth.subtext
            }

            StyledText {
              text: `${root.request?.source ?? ""} · system prompt`
              color: ConfigAuth.subtext
              font.pixelSize: ConfigAuth.metaSize
            }
          }
        }

        StyledRect {
          Layout.alignment: Qt.AlignTop
          visible: SAuth.phrase !== ""
          implicitWidth: phraseText.implicitWidth + 16
          implicitHeight: phraseText.implicitHeight + 4
          radius: ConfigAuth.chipRadius
          border.width: 1
          border.color: Theme.options.surface1

          StyledText {
            id: phraseText

            anchors.centerIn: parent
            text: SAuth.phrase
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.keycapSize
          }
        }
      }

      // body, width pinned so long labels wrap instead of widening the card
      ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: ConfigAuth.dialogWidth - ConfigAuth.dialogPadding * 2
        Layout.topMargin: 16
        Layout.bottomMargin: ConfigAuth.dialogPadding
        Layout.leftMargin: ConfigAuth.dialogPadding
        Layout.rightMargin: ConfigAuth.dialogPadding
        spacing: 12

        StyledText {
          Layout.fillWidth: true
          visible: text !== ""
          text: root.request?.message ?? ""
          wrapMode: Text.Wrap
          font.pixelSize: ConfigAuth.bodySize
          lineHeight: 20
          lineHeightMode: Text.FixedHeight
        }

        AuthDetails {
          Layout.fillWidth: true
          visible: rows.length > 0
          rows: root.request?.details ?? []
        }

        // single identity: plain row
        RowLayout {
          visible: root.identities.length === 1
          spacing: 8

          StyledRect {
            implicitWidth: 24
            implicitHeight: 24
            radius: width / 2
            color: Theme.options.surface0

            StyledText {
              anchors.centerIn: parent
              text: (root.identities[0]?.name ?? "").charAt(0)
              font.pixelSize: ConfigAuth.metaSize
              font.weight: Font.DemiBold
            }
          }

          StyledText {
            text: root.identities[0]?.name ?? ""
            font.pixelSize: ConfigAuth.bodySize
            font.weight: Font.Medium
          }

          StyledText {
            text: root.identities[0]?.detail ?? ""
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.metaSize
          }
        }

        AuthIdentityPicker {
          Layout.fillWidth: true
          visible: root.identities.length > 1
          enabled: !root.isLocked
          identities: root.identities
          selectedIndex: root.request?.selectedIdentity ?? 0
          onSelected: index => SAuth.selectIdentity(index)
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.hasInput
          spacing: 6

          StyledText {
            visible: root.isNewPassword
            text: "Password"
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.metaSize
            font.weight: Font.Medium
          }

          AuthField {
            id: passwordField

            Layout.fillWidth: true
            enabled: !root.isLocked
            placeholder: root.isNewPassword ? "" : (root.request?.prompt ?? "Password")
            nextField: root.isNewPassword ? confirmField : null
            isError: root.isError
            isSuccess: root.isSuccess
            onAccepted: {
              if (root.isNewPassword && confirmField.text === "") {
                confirmField.focusInput();
              } else {
                root.submit();
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.isNewPassword
          spacing: 6

          StyledText {
            text: "Confirm password"
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.metaSize
            font.weight: Font.Medium
          }

          AuthField {
            id: confirmField

            Layout.fillWidth: true
            enabled: !root.isLocked
            isError: confirmField.text !== "" && !passwordField.text.startsWith(confirmField.text)
            isSuccess: root.isSuccess
            onAccepted: root.submit()
          }
        }

        AuthStrength {
          id: strength

          Layout.fillWidth: true
          visible: root.isNewPassword
          password: passwordField.text
        }

        // status rows

        AuthStatusRow {
          Layout.fillWidth: true
          visible: root.isError && SAuth.errorText !== ""
          icon: "error"
          text: SAuth.errorText
          iconColor: Theme.options.red
          textColor: Theme.options.red
        }

        Repeater {
          model: root.request?.notes ?? []

          AuthStatusRow {
            required property var modelData

            Layout.fillWidth: true
            icon: modelData.icon
            text: modelData.text
            iconColor: modelData.tint ? ConfigAuth.tint(modelData.tint) : ConfigAuth.subtext
            textColor: modelData.isEmphasis ? Theme.options.text : ConfigAuth.subtext
          }
        }

        AuthStatusRow {
          Layout.fillWidth: true
          visible: root.hasInput && SCapslock.isLock && !root.isLocked
          icon: "keyboard_capslock"
          text: "Caps Lock is on"
          iconColor: Theme.options.yellow
        }

        AuthStatusRow {
          Layout.fillWidth: true
          visible: root.isNewPassword && confirmField.text !== ""
          icon: root.doPasswordsMatch ? "check_circle" : "error"
          text: root.doPasswordsMatch ? "Passwords match" : "Passwords don't match"
          iconColor: root.doPasswordsMatch ? Theme.options.green : Theme.options.red
          textColor: root.doPasswordsMatch ? Theme.options.text : Theme.options.red
        }

        AuthStatusRow {
          Layout.fillWidth: true
          visible: root.isSuccess
          icon: "check_circle"
          text: "Authenticated — closing"
          iconColor: Theme.options.green
          textColor: Theme.options.text
        }

        AuthStatusRow {
          Layout.fillWidth: true
          visible: (root.request?.timeout ?? 0) > 0 && !root.isLocked
          icon: "timer"
          iconFill: 0
          text: `No response — cancels automatically in ${Math.floor(root.remainingSeconds / 60)}:${String(root.remainingSeconds % 60).padStart(2, "0")}`
        }

        AuthCheckbox {
          Layout.fillWidth: true
          visible: root.request?.choice !== null && root.request?.choice !== undefined
          enabled: !root.isLocked
          label: root.request?.choice?.label ?? ""
          checked: root.isChoiceChecked
          onToggled: root.isChoiceChecked = !root.isChoiceChecked
        }
      }

      // actions
      RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: ConfigAuth.dialogPadding
        Layout.leftMargin: ConfigAuth.dialogPadding
        Layout.bottomMargin: 16
        visible: root.mode !== "notice" || (root.request?.cancelLabel ?? "") !== ""
        spacing: 8
        opacity: root.isSuccess ? 0.5 : 1

        AuthButton {
          visible: (root.request?.cancelLabel ?? "") !== ""
          label: root.request?.cancelLabel ?? ""
          keycap: "Esc"
          onClicked: root.cancel()
        }

        AuthButton {
          id: primaryButton

          visible: root.mode !== "notice"
          kind: "primary"
          enabled: root.canSubmit || root.isVerifying
          label: root.isSpinnerVisible ? "Verifying…" : (root.request?.okLabel ?? "OK")
          keycap: root.isSpinnerVisible ? "" : "↵"
          isBusy: root.isSpinnerVisible
          onClicked: root.submit()
        }
      }

      // requester strip, the timeout bar drains along its top edge
      StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: requesterRow.implicitHeight + 20
        visible: root.request?.requester !== null && root.request?.requester !== undefined
        color: Theme.options.mantle
        bottomLeftRadius: ConfigAuth.dialogRadius
        bottomRightRadius: ConfigAuth.dialogRadius

        StyledRect {
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }
          height: 1
          color: Theme.options.surface0
        }

        StyledRect {
          anchors {
            top: parent.top
            left: parent.left
          }
          visible: (root.request?.timeout ?? 0) > 0
          height: 2
          width: parent.width * (root.remainingSeconds / Math.max(1, root.request?.timeout ?? 1))
          color: ConfigAuth.ink

          Behavior on width {
            NumberAnimation {
              duration: 1000
            }
          }
        }

        RowLayout {
          id: requesterRow

          anchors {
            left: parent.left
            right: parent.right
            leftMargin: ConfigAuth.dialogPadding
            rightMargin: ConfigAuth.dialogPadding
            verticalCenter: parent.verticalCenter
          }
          spacing: 4

          StyledText {
            text: "Requested by"
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.metaSize
          }

          StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth
            text: root.request?.requester?.cmd ?? ""
            elide: Text.ElideRight
            font.pixelSize: ConfigAuth.metaSize
          }

          StyledText {
            Layout.fillWidth: true
            visible: (root.request?.requester?.pid ?? 0) > 0
            text: `(pid ${root.request?.requester?.pid ?? 0})`
            color: ConfigAuth.subtext
            font.pixelSize: ConfigAuth.metaSize
          }
        }
      }
    }

    // window edge on top of the content so the footer doesn't cover it
    StyledRect {
      anchors.fill: parent
      radius: ConfigAuth.dialogRadius
      border.width: 1
      border.color: ConfigAuth.edge
    }
  }
}
