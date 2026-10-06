pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pam

// lock screen state machine, owned by the lock instance (lock.qml), see
// design/project/LockInput.dc.html for the states
//
// Never log the password or anything PAM echoes back.
Singleton {
  id: root

  readonly property int maxAttempts: 3
  readonly property int lockoutSeconds: 30
  readonly property int maxFingerprintTries: 3
  readonly property int idleDimDelay: 30000
  // spinner shows only when PAM takes longer, avoids flicker
  readonly property int spinnerDelay: 300
  readonly property int successHold: 120
  readonly property int successFade: 250
  readonly property bool isFingerprintEnabled: Quickshell.env("QS_LOCK_FPRINT") === "1"

  property bool isLocked: false
  // empty | typing | verifying | wrong | lockout | success
  property string state: "empty"
  // idle | scanning | matched | nomatch | off
  property string fp: "off"
  property int attemptsLeft: root.maxAttempts
  property int fingerprintTriesLeft: root.maxFingerprintTries
  property int lockoutRemaining: 0
  // bumped on every failure, the field shakes on change
  property int errorCount: 0
  property bool isSpinnerVisible: false
  property bool isIdleDimmed: false
  property date lockedAt: new Date()
  // output that had focus at lock time, it gets the input, strip and dock
  property string focusedScreen: ""

  readonly property bool isVerifying: root.state === "verifying"
  readonly property bool isLockedOut: root.state === "lockout"
  readonly property bool isSuccess: root.state === "success"

  property string _buffer: ""

  function lock() {
    if (root.isLocked) {
      return;
    }
    root.focusedScreen = Hyprland.focusedMonitor?.name ?? "";
    root.lockedAt = new Date();
    root.reset();
    root.isLocked = true;
    root.isIdleDimmed = false;
    idleTimer.restart();
    root.startFingerprint();
    SSystemInfo.refresh();
    SWallpaper.refresh();
    SKeyboardLayout.refresh();
    Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "true"]);
  }

  // drops the lock without auth, only for development (QS_LOCK_DEV=1)
  function forceUnlock() {
    root.finishUnlock();
  }

  function reset() {
    passwordPam.abort();
    root._buffer = "";
    root.state = "empty";
    root.attemptsLeft = root.maxAttempts;
    root.lockoutRemaining = 0;
    root.isSpinnerVisible = false;
    lockoutTimer.stop();
    successTimer.stop();
  }

  // the field reports edits so the state leaves wrong/empty
  function setTyping(hasText) {
    if (root.state === "empty" || root.state === "typing" || root.state === "wrong") {
      root.state = hasText ? "typing" : (root.state === "wrong" ? "wrong" : "empty");
    }
  }

  function submit(password) {
    if (!root.isLocked || password === "" || root.isVerifying || root.isLockedOut || root.isSuccess) {
      return;
    }
    root._buffer = password;
    root.state = "verifying";
    root.isSpinnerVisible = false;
    spinnerTimer.restart();
    if (!passwordPam.start()) {
      root._buffer = "";
      root.fail();
    }
  }

  // any key or pointer motion on a lock surface
  function poke() {
    root.isIdleDimmed = false;
    if (root.isLocked) {
      idleTimer.restart();
    }
  }

  function succeed() {
    if (root.isSuccess) {
      return;
    }
    passwordPam.abort();
    fingerprintPam.abort();
    root._buffer = "";
    root.state = "success";
    root.isSpinnerVisible = false;
    root.isIdleDimmed = false;
    // surfaces hold, then fade, then the lock drops
    successTimer.restart();
  }

  function fail() {
    root._buffer = "";
    root.isSpinnerVisible = false;
    root.attemptsLeft = Math.max(0, root.attemptsLeft - 1);
    root.errorCount += 1;
    if (root.attemptsLeft === 0) {
      root.state = "lockout";
      root.lockoutRemaining = root.lockoutSeconds;
      lockoutTimer.restart();
      fingerprintPam.abort();
      root.fp = "off";
    } else {
      root.state = "wrong";
    }
  }

  function finishUnlock() {
    passwordPam.abort();
    fingerprintPam.abort();
    root._buffer = "";
    idleTimer.stop();
    lockoutTimer.stop();
    successTimer.stop();
    root.isIdleDimmed = false;
    root.isLocked = false;
    root.state = "empty";
    root.fp = "off";
    Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "false"]);
    // lets logind listeners (hypridle, the main shell SLock) know
    Quickshell.execDetached(["loginctl", "unlock-session"]);
  }

  function startFingerprint() {
    if (!root.isFingerprintEnabled || !root.isLocked || root.isLockedOut || root.isSuccess) {
      root.fp = "off";
      return;
    }
    root.fingerprintTriesLeft = root.maxFingerprintTries;
    root.fp = fingerprintPam.start() ? "idle" : "off";
  }

  PamContext {
    id: passwordPam

    config: "quickshell-lock"
    onPamMessage: {
      if (passwordPam.responseRequired) {
        passwordPam.respond(root._buffer);
        root._buffer = "";
      }
    }
    onCompleted: result => {
      if (!root.isVerifying) {
        return;
      }
      if (result === PamResult.Success) {
        root.succeed();
      } else {
        root.fail();
      }
    }
    onError: () => {
      if (root.isVerifying) {
        root.fail();
      }
    }
  }

  // pam_fprintd runs its own retry loop, messages only, no responses
  PamContext {
    id: fingerprintPam

    config: "quickshell-lock-fprint"
    onPamMessage: {
      if (!root.isLocked || root.isSuccess) {
        return;
      }
      if (fingerprintPam.messageIsError || /fail|no match|not match/i.test(fingerprintPam.message)) {
        root.fingerprintTriesLeft = Math.max(0, root.fingerprintTriesLeft - 1);
        root.fp = root.fingerprintTriesLeft > 0 ? "nomatch" : "off";
      } else {
        root.fp = "scanning";
      }
    }
    onCompleted: result => {
      if (result === PamResult.Success && root.isLocked && !root.isLockedOut) {
        root.fp = "matched";
        root.succeed();
      } else {
        root.fp = "off";
      }
    }
    onError: () => root.fp = "off"
  }

  Timer {
    id: spinnerTimer

    interval: root.spinnerDelay
    onTriggered: root.isSpinnerVisible = root.isVerifying
  }

  Timer {
    id: lockoutTimer

    interval: 1000
    repeat: true
    onTriggered: {
      root.lockoutRemaining = Math.max(0, root.lockoutRemaining - 1);
      if (root.lockoutRemaining === 0) {
        lockoutTimer.stop();
        root.attemptsLeft = root.maxAttempts;
        root.state = "empty";
        root.startFingerprint();
      }
    }
  }

  Timer {
    id: successTimer

    interval: root.successHold + root.successFade
    onTriggered: root.finishUnlock()
  }

  Timer {
    id: idleTimer

    interval: root.idleDimDelay
    onTriggered: root.isIdleDimmed = root.isLocked && !root.isSuccess
  }

  // crash recovery: a restarted lock daemon locks again when logind still
  // has the session marked locked
  Process {
    running: true
    command: ["loginctl", "show-session", "auto", "-p", "LockedHint", "--value"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim() === "yes") {
          root.lock();
        }
      }
    }
  }
}
