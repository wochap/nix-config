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

## Configuration

You can enable and configure mail accounts per-host. For example:

```nix
_custom.desktop.mail.enable = true;
_custom.desktop.mail.accounts.personal = {
  name = "Personal";
  address = "your.email@gmail.com";
  flavor = "gmail.com";
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
4. Save the app password to your secrets folder matching the lowercase account name (e.g. `~/.config/secrets/mail/<AccountName>`).
5. Create the `~/Mail/<AccountName>` directory along with the nested `mail/` Maildir structure if it doesn't exist:
   ```sh
   mkdir -p ~/Mail/<AccountName>/mail/{cur,new,tmp}
   ```
6. Initialize the Notmuch database:
   ```sh
   notmuch new
   ```
7. Authorize lieer for the first time. Since Home Manager already "initialized" the repo with the config file and you created the maildir folders, you only need to run the OAuth flow:
   ```sh
   cd ~/Mail/<AccountName>
   gmi auth
   ```
   This will open your browser and request OAuth access. The access token is stored in `.credentials.gmailieer.json`.
8. Run the initial sync. This may take a while for large mailboxes. You should stop `mailnotify` during this time so you aren't bombarded with notifications:
   ```sh
   systemctl --user stop mailnotify
   gmi pull
   systemctl --user start mailnotify
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
  - `<Tab>` in To/Cc fields: Auto-completes contacts from your entire mail history via `notmuch address`.
- **System Tray / Bar:**
  The status bar shows a mail badge with your unread inbox count.
- **Neovim (notmuch.nvim):**
  Reads the exact same notmuch database. Sends are routed through `offlinemsmtp` so your workflow remains robust even when offline.
