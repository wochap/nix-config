## Email setup

Mails are saved to `~/Mail` folder

### Stack

- Neomutt
  email TUI
  - Mailcap
    define mimetypes for email content
- Mailnotify
  notifies when mail has arrived in your mail directory
- imapnotify
  notifies you of new e-mails coming in
- Mbsync
  synchronizes mailboxes
- msmtp
  simple and easy-to-use SMTP client with fairly complete sendmail compatibility
- Offlinemsmtp
  allows you to use msmtp offline by queuing email until you have an internet connection
- smtp
  protocol to send mails

### Setup

Add a file in `<NIX_CONFIG_PATH>/secrets/mail/<EMAIL>`, and inside paste the password/token/app_password

### Passwords for Gmail

You must enable 2FA auth in your google account and create a password in "App passwords"

In Gmail > Settings > Forwarding and POP/IMAP, enable POP and IMAP

