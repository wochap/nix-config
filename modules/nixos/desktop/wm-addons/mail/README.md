# Mail Setup

Mails are stored locally in the `~/Mail` folder.

This module sets up a complete email environment using standard NixOS and home-manager options, exposing `_custom.desktop.mail.accounts.<name>` so every host can configure its own mail accounts flexibly.

## Stack

- **Neomutt:**
  Command-line email client (TUI) with notmuch virtual folders.
  - **Mailcap:** Defines mimetypes for rendering email content (e.g., HTML, attachments).
- **Mailnotify:**
  Desktop notification daemon that alerts you when new mail lands in your mail directory.
- **Goimapnotify:**
  Watches your IMAP server for changes (IMAP IDLE) and triggers sync scripts (configured natively via `services.imapnotify`).
- **Lieer:**
  Synchronizes Gmail accounts (mapping Gmail labels <-> notmuch tags) using the Gmail API, completely avoiding IMAP sync quirks.
- **Mbsync (isync):**
  Standard synchronizer for non-Gmail IMAP accounts (only enabled when `sync = "mbsync"` is set for an account).
- **Notmuch:**
  Blazing fast mail indexer and search tool. Powers the virtual folders in Neomutt.
- **msmtp:**
  Simple SMTP client for sending outgoing mail.
- **Offlinemsmtp:**
  Queues outgoing email using msmtp. Useful if you try to send emails while disconnected from the internet.

## Syncing

Mail sync units run periodically and are also started whenever
NetworkManager brings a connection up, so they do not wait for the next timer
after boot, resume, or reconnect. An `ExecCondition` skips timer runs while
offline without marking the unit failed or firing its failure notification.

## Configuration

You can enable and configure mail accounts per-host. For example:

```nix
_custom.desktop.mail.enable = true;
_custom.desktop.mail.accounts.personal = {
  name = "Personal";
  address = "your.email@gmail.com";
  flavor = "gmail.com";
  passwordSecret.sopsFile = ../../secrets-sops/personal.yaml;
  passwordSecret.sopsKey = "personal-mail-password";
  sync = "lieer"; # or "mbsync"
  color = "red";
  pgpKey = "YOUR_GPG_KEY_ID";
  signatureLines = [
    [ "Your Name" "Software Engineer" ]
    [ "https://yourwebsite.com" ]
  ];
};
```

## Initial Setup

### Gmail (Lieer)

Lieer syncs through the Gmail API using OAuth, while `goimapnotify` watches IMAP and needs an app password.

1. Enable 2FA in your Google account.
2. In Gmail > Settings > Forwarding and POP/IMAP, enable POP and IMAP.
3. Generate an [App Password](https://support.google.com/accounts/answer/185833?hl=en).
4. Save the app password in the account's `passwordSecret.sopsFile` under the configured `passwordSecret.sopsKey`. The same key determines the runtime path (for example, `passwordSecret.sopsKey = "personal-mail-password"` uses `/run/secrets/personal-mail-password`).
5. Create the `~/Mail/<AccountName>` directory along with the nested `mail/` Maildir structure if it doesn't exist:
   ```sh
   mkdir -p ~/Mail/<AccountName>/mail/{cur,new,tmp}
   ```
6. Initialize the Notmuch database (once works for all accounts):
   ```sh
   notmuch new
   ```
7. Authorize lieer for the first time. Since Home Manager already "initialized" the repo with the config file and you created the maildir folders, you only need to run the OAuth flow:

   ```sh
   cd ~/Mail/<AccountName>
   gmi auth
   ```

   This will open your browser and request OAuth access. The access token is stored in `.credentials.gmailieer.json`.

   Note that `.gmailieer.json` is managed by Home Manager (a symlink into the
   Nix store), so do not edit it by hand or with `gmi set` — change
   `_custom.hm.accounts.email.accounts.<name>.lieer.settings` in your Nix
   config instead (any manual change is reverted on the next activation).

8. Run the initial sync. This is a full synchronization and can take hours on
   large mailboxes (the Gmail API is heavily rate limited). Stop `mailnotify`
   so you aren't bombarded with notifications while the pull downloads
   everything, and stop the account's sync units so nothing interferes (the
   `lieer-<AccountName>` service additionally refuses to run until
   `.state.gmailieer.json` exists, i.e. until this initial pull has
   completed, but stopping the rest keeps things quiet):

   ```sh
   systemctl --user stop mailnotify lieer-<AccountName>.timer lieer-<AccountName>.service imapnotify-<AccountName>.service
   cd ~/Mail/<AccountName>
   gmi pull
   ```

   - Let it finish: the sync cursors in `.state.gmailieer.json` are only
     written when the pull completes. If it gets interrupted anyway, continue
     with `gmi pull --resume`, and do not start the sync services until the
     initial pull has fully completed.
   - If you have several accounts, initialize them one at a time.
   - When done, verify the state is healthy before re-enabling the services:
     ```sh
     cat .state.gmailieer.json    # both last_historyId and lastmod must be non-zero
     gmi push                     # should print "push: everything is up-to-date."
     systemctl --user start mailnotify lieer-<AccountName>.timer imapnotify-<AccountName>.service
     ```

9. (Optional) Apply initial tags directly in the notmuch database:
   ```sh
   notmuch config set --database new.tags unread inbox
   ```

### Other Providers (Mbsync)

Set `sync = "mbsync"` in the account configuration. Mbsync perfectly mirrors IMAP folders to your local Maildir, and `notmuch` indexes everything automatically.

The initial synchronization can also be kicked off using `email-sync`.

## Extras

- **Neomutt Shortcuts:**
  - `Ctrl-s`: Ad-hoc notmuch query as a virtual folder
  - `f`: Edit notmuch tags
  - `D`: Add trash tag
  - `A`: Archive (remove inbox tag)
  - `v`: Select attachments
  - `o` / `Enter`: Open the selected attachment according to the session
  - `B` / `T`: Open HTML or the selected attachment graphically / in the terminal
  - `J` / `K`: Next / previous unread message
  - `gt` / `gT`: Next / previous thread
  - `za` / `zA`: Collapse the current thread / all threads
  - `<Tab>` in To/Cc fields: Auto-completes contacts from your entire mail history via `notmuch address`.
- **System Tray / Bar:**
  The status bar shows a mail badge with your unread inbox count.
- **Neovim (notmuch.nvim):**
  Reads the exact same notmuch database. Sends are routed through `offlinemsmtp` so your workflow remains robust even when offline.

## Hooks

`_custom.desktop.mail.accounts.<name>.hooks` runs arbitrary commands in
response to mail events of that account. Hooks are implemented as a notmuch
post-new hook, so they fire on every sync path that imports new mail — lieer
(`gmi pull`) and mbsync (`mbsync ... && notmuch new`). That means seconds
after arrival (IMAP IDLE push triggers the sync), with the sync timers as
fallback.

### `hooks.arrive`

A per-account list of `{ from, command }` entries. For each new message in
the account's mail folder matching the `from` sender glob, the command runs
once with:

- `$1`: notmuch message id
- `$2`: From header
- `$3`: Subject header
- `$4`: Date header
- stdin: full message text (headers + body)
- same values exported as `MAIL_ID`, `MAIL_FROM`, `MAIL_SUBJECT`, `MAIL_DATE`

```nix
_custom.desktop.mail.accounts.personal = {
  # ...
  hooks.arrive = [
    {
      from = "*@github.com";
      command = "${pkgs.libnotify}/bin/notify-send 'New GitHub notification'";
    }
  ];
};
```

Notes:

- Queries are scoped to the account's mail folder (same scoping as the
  neomutt virtual folders), so hooks only fire for this account's mail.
  Requires `sync = "lieer"` or `"mbsync"` (mail of `sync = "none"` accounts
  is never imported).
- `from` is a notmuch sender glob (e.g. `*@github.com`, `alice@example.org`);
  the guard query is `tag:new and from:<glob> and folder:<account-folder>`.
- `command` is executed by bash inside the post-new hook. Use **absolute
  paths** for any binaries so the hook works regardless of the PATH inherited
  from the sync unit that triggered it.
- All matching entries fire, in declaration order.
- Command failures are absorbed (`|| true`) so they cannot fail `notmuch new`
  and break the sync unit; check `journalctl --user -u lieer-<name>` for
  their stderr.
- Keep commands cheap — the hook runs inline before the sync finishes.

## Troubleshooting

### Sync takes hours and notifications arrive late (or never)

`gmi` keeps two cursors in `~/Mail/<AccountName>/.state.gmailieer.json`:

- `last_historyId`: how far remote changes have been **pulled** (history based, cheap).
- `lastmod`: the notmuch database revision up to which local tag changes have been **pushed**.

If `lastmod` falls far behind the current database revision, the push phase
queries every message changed since then and fetches its metadata from the
(heavily rate limited) Gmail API. On a large mailbox that takes hours, and
since `gmi sync` pushes _before_ it pulls, the pull — and with it mail
delivery and mailnotify notifications — is blocked the whole time. Worse, a
push only advances `lastmod` when nothing was skipped, so once stuck it tends
to stay stuck. The sync service is configured to pull first and push second
to keep mail flowing, but a badly stale `lastmod` still needs a one-time
repair:

```sh
systemctl --user stop lieer-personal.service lieer-personal.timer
cd ~/Mail/personal
rev=$(NOTMUCH_CONFIG=~/.config/notmuch/default/config notmuch count --lastmod | cut -f2)
python3 -c "import json; s = json.load(open('.state.gmailieer.json')); s['lastmod'] = $rev; json.dump(s, open('.state.gmailieer.json', 'w'))"
gmi push   # should now print "push: everything is up-to-date."
systemctl --user start lieer-personal.timer
```

This skips pushing any local tag changes made before the repair, which is
safe right after a successful `gmi pull` (local tags already mirror the
remote labels).
