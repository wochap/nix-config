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
  // pam_fprintd gives up after ~30s without a finger and fprintd refuses
  // verifies while the system suspends, so a dead context is restarted
  readonly property int fingerprintRetryMin: 2000
  readonly property int fingerprintRetryMax: 30000

  property bool isLocked: false
  // between logind PrepareForSleep(true) and PrepareForSleep(false)
  property bool isSleeping: false
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
  property int _fingerprintRetryDelay: root.fingerprintRetryMin

  function lock() {
    if (root.isLocked) {
      // a second lock-session while locked (sleep while locked) revives a
      // dead fingerprint context
      if (root.fp === "off") {
        root.startFingerprint();
      }
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
    fingerprintRetryTimer.stop();
    root.isIdleDimmed = false;
    root.isLocked = false;
    root.state = "empty";
    root.fp = "off";
    Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "false"]);
    // lets logind listeners (hypridle, the main shell SLock) know
    Quickshell.execDetached(["loginctl", "unlock-session"]);
  }

  function startFingerprint() {
    fingerprintRetryTimer.stop();
    if (!root.isFingerprintEnabled || !root.isLocked || root.isLockedOut || root.isSuccess) {
      root.fp = "off";
      return;
    }
    // fprintd fails to claim the reader while suspending, wake restarts
    if (root.isSleeping) {
      root.fp = "off";
      return;
    }
    root.fingerprintTriesLeft = root.maxFingerprintTries;
    fingerprintPam.abort();
    if (fingerprintPam.start()) {
      root.fp = "idle";
    } else {
      root.fp = "off";
      root.scheduleFingerprintRetry();
    }
  }

  // a context that ended without a verdict (timeout, fprintd error) comes
  // back with growing delays, a context that spent its tries stays off
  function scheduleFingerprintRetry() {
    if (!root.isFingerprintEnabled || !root.isLocked || root.isLockedOut || root.isSuccess || root.isSleeping) {
      return;
    }
    if (root.fingerprintTriesLeft === 0) {
      return;
    }
    fingerprintRetryTimer.interval = root._fingerprintRetryDelay;
    fingerprintRetryTimer.restart();
    root._fingerprintRetryDelay = Math.min(root._fingerprintRetryDelay * 2, root.fingerprintRetryMax);
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
        // the reader answered, fprintd is healthy again
        root._fingerprintRetryDelay = root.fingerprintRetryMin;
        root.fp = "scanning";
      }
    }
    onCompleted: result => {
      if (result === PamResult.Success && root.isLocked && !root.isLockedOut) {
        root.fp = "matched";
        root.succeed();
      } else {
        root.fp = "off";
        root.scheduleFingerprintRetry();
      }
    }
    onError: () => {
      root.fp = "off";
      root.scheduleFingerprintRetry();
    }
  }

  Timer {
    id: fingerprintRetryTimer

    interval: root.fingerprintRetryMin
    onTriggered: {
      if (root.isLocked && root.fp === "off") {
        root.startFingerprint();
      }
    }
  }

  // logind PrepareForSleep: the context dies when the lock comes from
  // before_sleep_cmd (fprintd refuses verifies mid-suspend) and a reader that
  // slept through a long lock needs a fresh VerifyStart on wake
  Process {
    running: true
    command: ["dbus-monitor", "--system", "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim();
        if (line === "boolean true") {
          root.isSleeping = true;
          fingerprintRetryTimer.stop();
          fingerprintPam.abort();
          if (root.fp !== "off") {
            root.fp = "off";
          }
        } else if (line === "boolean false") {
          root.isSleeping = false;
          root._fingerprintRetryDelay = root.fingerprintRetryMin;
          if (root.isLocked) {
            root.startFingerprint();
          }
        }
      }
    }
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
