## Email setup

Mails are saved to `~/Mail` folder

### Stack

- Neomutt:
  email TUI
  - Mailcap:
    define mimetypes for email content
- Mailnotify:
  notifies when mail has arrived in your mail directory
- imapnotify:
  notifies you of new e-mails coming in
- Mbsync:
  synchronizes mailboxes
- msmtp:
  simple and easy-to-use SMTP client with fairly complete sendmail compatibility
- Offlinemsmtp:
  allows you to use msmtp offline by queuing email until you have an internet connection
- smtp:
  protocol to send mails

### Setup

#### Gmail

1. Enable 2FA auth in your google account
1. In Gmail > Settings > Forwarding and POP/IMAP, enable POP and IMAP
1. Generate a [app_password](https://support.google.com/accounts/answer/185833?hl=en), go to [Google Account](https://myaccount.google.com/) > Security > 2-Step Verification > App passwords
1. Add a file in `<NIX_CONFIG_PATH>/secrets/mail/<EMAIL>`, and paste the password/token/app_password (e.g. 16 digits)
