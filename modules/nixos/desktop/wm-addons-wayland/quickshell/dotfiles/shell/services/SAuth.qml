pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Polkit

// Queue of auth prompts shown by widgets/AuthPrompt.
// Sources: the in-process polkit agent, and `shell-auth` clients (pinentry,
// ssh askpass, gnome-keyring system prompter) talking JSON lines over a unix socket.
// Never log request or reply objects, they carry secrets.
Singleton {
  id: root

  readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-auth.sock`
  // set by the nix module, an unconditional agent would race hyprpolkitagent
  readonly property bool isPolkitEnabled: Quickshell.env("QS_AUTH_POLKIT") === "1"
  readonly property var polkitAgent: polkitLoader.item

  // normalized request of the visible dialog, null when idle
  property var current: null
  // default | verifying | error | success
  property string state: "default"
  property string errorText: ""
  // bumped on every failure, the dialog shakes on change
  property int errorCount: 0
  // monitor the dialog opened on, kept while the queue drains
  property string screenName: ""
  // anti-spoofing phrase shown in the dialog header
  property string phrase: ""

  property var _queue: []
  property var _currentEntry: null
  property int _nextUid: 1
  property bool _isSwitchingIdentity: false

  readonly property var _sourceStyles: ({
      "polkit": {
        icon: "admin_panel_settings",
        tint: "peach"
      },
      "gpg-agent": {
        icon: "key",
        tint: "mauve"
      },
      "ssh": {
        icon: "terminal",
        tint: "sky"
      },
      "gnome-keyring": {
        icon: "passkey",
        tint: "yellow"
      }
    })

  // result: ok | cancel | timeout
  function respond(result, password, choice, strength) {
    const entry = root._currentEntry;
    if (!entry || root.state === "success") {
      return;
    }
    const isOk = result === "ok";
    if (entry.origin === "socket") {
      entry.socket.write(JSON.stringify({
        result: result,
        password: isOk ? (password ?? "") : "",
        choice: choice ?? false,
        strength: strength ?? 0
      }) + "\n");
      entry.socket.flush();
      if (isOk) {
        // the client closes the connection on success or sends the
        // next prompt (with an error) on failure
        root.state = "verifying";
      } else {
        root._remove(entry);
      }
    } else if (entry.origin === "polkit") {
      // entry.flow is null once the flow completed (it gets deleted)
      const flow = entry.flow;
      if (isOk && flow) {
        root.state = "verifying";
        flow.submit(password ?? "");
      } else {
        if (flow) {
          flow.cancelAuthenticationRequest();
        }
        root._remove(entry);
      }
    } else if (entry.origin === "test") {
      if (isOk) {
        root.state = "verifying";
        testTimer.password = password ?? "";
        testTimer.restart();
      } else {
        root._remove(entry);
      }
    }
  }

  function cancel() {
    root.respond("cancel");
  }

  function selectIdentity(index) {
    const entry = root._currentEntry;
    if (!entry || entry.origin !== "polkit") {
      return;
    }
    const identity = entry.flow?.identities?.[index];
    if (!identity || identity === entry.flow.selectedIdentity) {
      return;
    }
    root._selectPolkitIdentity(entry.flow, identity);
    root._refreshPolkit(entry);
  }

  function _enqueue(entry) {
    entry.uid = root._nextUid++;
    entry.request.uid = entry.uid;
    root._queue = [...root._queue, entry];
    root._advance();
  }

  function _remove(entry) {
    root._queue = root._queue.filter(e => e !== entry);
    if (entry.socket) {
      entry.socket.entry = null;
    }
    if (root._currentEntry === entry) {
      root._currentEntry = null;
      root._advance();
    }
  }

  function _advance() {
    if (root._currentEntry) {
      return;
    }
    const next = root._queue[0] ?? null;
    if (!next) {
      root.current = null;
      return;
    }
    if (!root.current) {
      root.screenName = Hyprland.focusedMonitor?.name ?? "";
    }
    root._currentEntry = next;
    root.state = next.request.error ? "error" : "default";
    root.errorText = next.request.error ?? "";
    root.current = next.request;
  }

  // update a queued entry, e.g. a retry after a wrong password
  function _update(entry, request, isFailure) {
    request.uid = entry.uid;
    entry.request = request;
    if (root._currentEntry !== entry) {
      return;
    }
    root.current = request;
    if (isFailure) {
      root.state = "error";
      root.errorText = request.error;
      root.errorCount++;
    } else if (root.state !== "verifying") {
      root.state = "default";
    }
  }

  function _normalize(req) {
    const style = root._sourceStyles[req.source] ?? root._sourceStyles["polkit"];
    const mode = req.mode ?? "password";
    return {
      source: req.source ?? "",
      icon: req.icon ?? style.icon,
      tint: req.tint ?? style.tint,
      title: req.title ?? "Authentication required",
      message: req.message ?? "",
      details: (req.details ?? []).map(d => ({
            label: d[0] ?? "",
            value: d[1] ?? "",
            isMono: d[2] ?? false
          })),
      notes: (req.notes ?? []).map(n => ({
            icon: n.icon ?? "info",
            tint: n.tint ?? "",
            text: n.text ?? "",
            isEmphasis: n.emphasis ?? false
          })),
      mode: mode,
      prompt: req.prompt ?? "Password",
      error: req.error ?? "",
      choice: req.choice?.label ? {
        label: req.choice.label,
        checked: req.choice.checked ?? false
      } : null,
      okLabel: req.ok ?? (mode === "confirm" ? "OK" : "Unlock"),
      // an empty label hides the cancel button (pinentry MESSAGE)
      cancelLabel: req.cancel ?? "Cancel",
      timeout: req.timeout ?? 0,
      requester: req.requester?.cmd ? {
        cmd: req.requester.cmd,
        pid: req.requester.pid ?? 0
      } : null,
      identities: req.identities ?? [],
      selectedIdentity: req.selectedIdentity ?? 0,
      isResponseVisible: req.responseVisible ?? false
    };
  }

  // polkit

  function _polkitRequest(flow) {
    const identities = (flow.identities ?? []).map(i => ({
          name: i.displayName || i.string,
          detail: i.isGroup ? "unix-group" : "unix-user",
          isGroup: i.isGroup
        }));
    const selected = Math.max(0, (flow.identities ?? []).indexOf(flow.selectedIdentity));
    return root._normalize({
      source: "polkit",
      title: "Authentication required",
      message: flow.message,
      details: flow.actionId ? [["Action", flow.actionId, true]] : [],
      prompt: (flow.inputPrompt || "Password").replace(/:\s*$/, ""),
      ok: "Authenticate",
      identities: identities,
      selectedIdentity: selected,
      responseVisible: flow.responseVisible
    });
  }

  function _refreshPolkit(entry) {
    if (entry.flow) {
      root._update(entry, root._polkitRequest(entry.flow), false);
    }
  }

  // prefer the logged in user over polkit's default (often root)
  function _selectCurrentUser(flow) {
    const identities = flow?.identities ?? [];
    if (identities.length < 2) {
      return;
    }
    const userName = Quickshell.env("USER");
    const identity = identities.find(i => !i.isGroup && i.string === userName);
    if (identity && identity !== flow.selectedIdentity) {
      root._selectPolkitIdentity(flow, identity);
    }
  }

  // Connected per flow instead of through `polkitAgent.flow`: on completion the
  // agent clears `flow` (and deleteLater()s it) before authenticationSucceeded
  // is emitted, a Connections bound to it would miss the result
  function _watchFlow(entry) {
    const flow = entry.flow;
    flow.isCompletedChanged.connect(() => {
      if (!flow.isCompleted || !entry.flow) {
        return;
      }
      entry.flow = null;
      if (flow.isSuccessful && root._currentEntry === entry) {
        root.state = "success";
        successTimer.entry = entry;
        successTimer.restart();
      } else {
        root._remove(entry);
      }
    });
    flow.authenticationFailed.connect(() => {
      if (root._isSwitchingIdentity || !entry.flow) {
        return;
      }
      const request = root._polkitRequest(flow);
      request.error = flow.supplementaryIsError && flow.supplementaryMessage ? flow.supplementaryMessage : "Wrong password. Try again.";
      root._update(entry, request, true);
    });
    flow.authenticationRequestCancelled.connect(() => {
      entry.flow = null;
      root._remove(entry);
    });
    flow.inputPromptChanged.connect(() => {
      if (entry.flow && root.state !== "error") {
        root._refreshPolkit(entry);
      }
    });
    flow.responseVisibleChanged.connect(() => {
      if (entry.flow) {
        root._refreshPolkit(entry);
      }
    });
  }

  // assigning selectedIdentity restarts the session, which polkit reports as
  // a failure, swallow it
  function _selectPolkitIdentity(flow, identity) {
    root._isSwitchingIdentity = true;
    flow.selectedIdentity = identity;
    root._isSwitchingIdentity = false;
  }

  LazyLoader {
    id: polkitLoader

    active: root.isPolkitEnabled

    PolkitAgent {}
  }

  Connections {
    target: root.polkitAgent

    function onAuthenticationRequestStarted() {
      const flow = root.polkitAgent.flow;
      root._selectCurrentUser(flow);
      const entry = {
        origin: "polkit",
        flow: flow,
        request: root._polkitRequest(flow)
      };
      root._watchFlow(entry);
      root._enqueue(entry);
    }

    function onIsRegisteredChanged() {
      if (!root.polkitAgent.isRegistered) {
        console.warn("SAuth: polkit agent not registered, another agent may own the session");
      }
    }
  }

  // shell-auth clients

  SocketServer {
    active: true
    path: root.socketPath
    handler: Socket {
      id: client

      property var entry: null

      onConnectedChanged: {
        if (!client.connected && client.entry) {
          root._remove(client.entry);
        }
      }

      parser: SplitParser {
        onRead: line => {
          let message;
          try {
            message = JSON.parse(line);
          } catch (e) {
            console.warn("SAuth: invalid message from client");
            return;
          }
          if (message.type === "prompt") {
            const request = root._normalize(message);
            if (client.entry) {
              root._update(client.entry, request, request.error !== "");
            } else {
              client.entry = {
                origin: "socket",
                socket: client,
                request: request
              };
              root._enqueue(client.entry);
            }
          } else if (message.type === "close" && client.entry) {
            root._remove(client.entry);
          }
        }
      }
    }
  }

  // success state stays visible briefly before the dialog closes
  Timer {
    id: successTimer

    property var entry: null

    interval: 400
    onTriggered: {
      if (successTimer.entry) {
        root._remove(successTimer.entry);
        successTimer.entry = null;
      }
    }
  }

  FileView {
    id: phraseFile

    path: "/run/secrets/personal-auth-phrase"
    printErrors: false
    onLoaded: root.phrase = phraseFile.text().trim()
  }

  // visual checks: `qs ipc call auth test <variant>`, password "test" succeeds

  Timer {
    id: testTimer

    property string password: ""

    interval: 700
    onTriggered: {
      const entry = root._currentEntry;
      if (!entry || entry.origin !== "test") {
        return;
      }
      if (testTimer.password === "test") {
        root.state = "success";
        successTimer.entry = entry;
        successTimer.restart();
      } else {
        const request = Object.assign({}, entry.request, {
          error: "Wrong password. Try again."
        });
        root._update(entry, request, true);
      }
    }
  }

  readonly property var _testRequests: ({
      "polkit": {
        source: "polkit",
        message: "Authentication is required to reload the systemd state.",
        details: [["Action", "org.freedesktop.systemd1.reload-daemon", true]],
        ok: "Authenticate",
        identities: [
          {
            name: Quickshell.env("USER"),
            detail: "unix-user"
          }
        ]
      },
      "polkit-multi": {
        source: "polkit",
        message: "Authentication is required to mount “Backup” for all users.",
        details: [["Action", "org.freedesktop.udisks2.filesystem-mount-system", true]],
        ok: "Authenticate",
        identities: [
          {
            name: "root",
            detail: "unix-user"
          },
          {
            name: Quickshell.env("USER"),
            detail: "unix-user"
          },
          {
            name: "wheel",
            detail: "unix-group"
          }
        ],
        selectedIdentity: 1
      },
      "gpg": {
        source: "gpg-agent",
        title: "Unlock OpenPGP key",
        message: "Enter the passphrase to sign with this key.",
        details: [["User ID", "Jane Doe <jane@example.org>", false], ["Key ID", "ed25519 / 9F2C 41A8 7B3E D0C4", true], ["Created", "2025-03-14", false]],
        prompt: "Passphrase",
        choice: {
          label: "Save in keyring",
          checked: false
        },
        timeout: 30,
        requester: {
          cmd: "git commit -S",
          pid: 7213
        }
      },
      "ssh-key": {
        source: "ssh",
        title: "Unlock SSH key",
        message: "Enter the passphrase for this private key.",
        details: [["Key", "~/.ssh/id_ed25519", true], ["Fingerprint", "SHA256:q3VxN8c1KfR0pZ7mW2bT5yLh9dGs4jE6uA0oXi1CkYw", true]],
        prompt: "Passphrase",
        requester: {
          cmd: "ssh git@github.com",
          pid: 9932
        }
      },
      "ssh-host": {
        source: "ssh",
        icon: "dns",
        title: "Unknown host",
        message: "This host isn't in your known hosts. Compare the fingerprint with one from the server's owner before you connect.",
        details: [["Host", "build.lan (192.168.1.40:22)", true], ["Key type", "ED25519", false], ["Fingerprint", "SHA256:Vb2x7kQe0rL9nM4pT1sYw8ZcH6uJ3fA5gD2iK7oP9qE", true]],
        notes: [
          {
            icon: "warning",
            tint: "yellow",
            text: "First connection — not in ~/.ssh/known_hosts",
            emphasis: true
          }
        ],
        mode: "confirm",
        ok: "Accept",
        cancel: "Reject",
        requester: {
          cmd: "ssh deploy@build.lan",
          pid: 10288
        }
      },
      "keyring": {
        source: "gnome-keyring",
        title: "Unlock keyring",
        message: "An application wants access to the keyring “Login”, but it is locked.",
        details: [["Keyring", "Login", true]],
        prompt: "Password for “Login”",
        choice: {
          label: "Automatically unlock this keyring whenever I'm logged in",
          checked: false
        }
      },
      "keyring-new": {
        source: "gnome-keyring",
        title: "Create keyring password",
        message: "Choose a password for the new keyring “Work”. You'll need it to unlock the keyring.",
        mode: "new-password",
        ok: "Create"
      },
      "notice": {
        source: "ssh",
        icon: "fingerprint",
        title: "Confirm user presence",
        message: "Touch your security key to authenticate.",
        details: [["Key", "ED25519-SK SHA256:Qm3xR8…", true]],
        mode: "notice",
        requester: {
          cmd: "ssh git@github.com",
          pid: 9932
        }
      }
    })

  IpcHandler {
    target: "auth"

    // variants: polkit, polkit-multi, gpg, ssh-key, ssh-host, keyring, keyring-new, notice
    function test(variant: string): void {
      const request = root._testRequests[variant];
      if (!request) {
        console.warn(`SAuth: unknown test variant ${variant}`);
        return;
      }
      root._enqueue({
        origin: "test",
        request: root._normalize(request)
      });
    }

    function cancel(): void {
      root.cancel();
    }
  }
}
