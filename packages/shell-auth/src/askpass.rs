//! ssh askpass. ssh runs `$SSH_ASKPASS "<prompt>"` and reads the answer from
//! stdout; `SSH_ASKPASS_PROMPT` is `confirm` (exit status is the answer) or
//! `none` (FIDO user presence notice, ssh kills us once the key is touched).
//!
//! Keys managed by gcr-ssh-agent never get here, the agent prompts through the
//! gnome-keyring system prompter instead (see prompter.rs).

use crate::fallback;
use crate::process;
use crate::socket::{Client, Note, Request};

pub fn run(args: Vec<String>) -> u8 {
    let mut client = match Client::connect() {
        Ok(client) => client,
        Err(_) => return fallback::exec(fallback::ASKPASS, &args),
    };

    let prompt = args.join(" ");
    let kind = std::env::var("SSH_ASKPASS_PROMPT").unwrap_or_default();
    let mut request = build_request(&prompt, &kind);
    request.requester = process::requester(std::os::unix::process::parent_id());

    if request.mode == "notice" {
        if client.show(&request).is_err() {
            return 1;
        }
        // stays up until ssh terminates us, or the user dismisses it
        client.wait();
        return 0;
    }

    let reply = match client.prompt(&request) {
        Ok(reply) => reply,
        Err(_) => return 1,
    };
    client.close();
    if !reply.is_ok() {
        return 1;
    }
    if request.mode == "confirm" {
        println!("yes");
    } else {
        println!("{}", reply.password);
    }
    0
}

fn build_request(prompt: &str, kind: &str) -> Request {
    let prompt = prompt.trim();

    if kind == "none" {
        let mut request = Request::new("ssh", "notice");
        request.icon = Some("fingerprint".into());
        request.title = "Confirm user presence".into();
        request.message = prompt.to_string();
        request.cancel = Some("Dismiss".into());
        return request;
    }

    if prompt.contains("authenticity of host") {
        return host_key_request(prompt);
    }

    if kind == "confirm" {
        let mut request = Request::new("ssh", "confirm");
        request.title = "Confirm".into();
        request.message = prompt.to_string();
        request.ok = Some("Allow".into());
        request.cancel = Some("Deny".into());
        return request;
    }

    if let Some(key) = passphrase_key(prompt) {
        let mut request = Request::new("ssh", "password");
        request.title = "Unlock SSH key".into();
        request.message = "Enter the passphrase for this private key.".into();
        request
            .details
            .push(("Key".into(), shorten_home(&key), true));
        if let Some(fingerprint) = fingerprint(&key) {
            request
                .details
                .push(("Fingerprint".into(), fingerprint, true));
        }
        request.prompt = Some("Passphrase".into());
        return request;
    }

    if let Some(account) = prompt.strip_suffix("'s password:") {
        let mut request = Request::new("ssh", "password");
        request.icon = Some("dns".into());
        request.title = "SSH login".into();
        request.message = "Enter the password for this account.".into();
        request
            .details
            .push(("Account".into(), account.to_string(), true));
        request.ok = Some("Log in".into());
        return request;
    }

    let mut request = Request::new("ssh", "password");
    request.title = "SSH".into();
    request.message = prompt.to_string();
    request.ok = Some("OK".into());
    request
}

/// "Enter passphrase for key '/home/u/.ssh/id_ed25519': " (ssh) or
/// "Enter passphrase for /home/u/.ssh/id_ed25519 (comment): " (ssh-add)
fn passphrase_key(prompt: &str) -> Option<String> {
    let rest = prompt.strip_prefix("Enter passphrase for ")?;
    let rest = rest.trim_end_matches(':').trim();
    if let Some(quoted) = rest.strip_prefix("key '") {
        return Some(quoted.split('\'').next()?.to_string());
    }
    Some(rest.split(" (").next()?.trim().to_string())
}

fn host_key_request(prompt: &str) -> Request {
    let mut request = Request::new("ssh", "confirm");
    request.icon = Some("dns".into());
    request.title = "Unknown host".into();
    request.message = "This host isn't in your known hosts. Compare the fingerprint with one from the server's owner before you connect.".into();

    if let Some(host) = between(prompt, "host '", "'") {
        request
            .details
            .push(("Host".into(), host.to_string(), true));
    }
    // "ED25519 key fingerprint is SHA256:xxx."
    if let Some(line) = prompt
        .lines()
        .find(|line| line.contains(" key fingerprint is "))
    {
        let mut parts = line.splitn(2, " key fingerprint is ");
        let key_type = parts.next().unwrap_or_default().trim();
        let fingerprint = parts
            .next()
            .unwrap_or_default()
            .trim()
            .trim_end_matches('.');
        request
            .details
            .push(("Key type".into(), key_type.to_string(), false));
        request
            .details
            .push(("Fingerprint".into(), fingerprint.to_string(), true));
    }
    // ssh lists other names the key is known by, worth showing as is
    let known_as: Vec<&str> = prompt
        .lines()
        .filter(|line| line.contains("known by") || line.starts_with("    "))
        .map(str::trim)
        .collect();
    let note = if known_as.is_empty() || known_as[0].contains("not known by any other names") {
        "First connection — not in ~/.ssh/known_hosts".to_string()
    } else {
        known_as.join(" ")
    };
    request.notes.push(Note {
        icon: "warning".into(),
        tint: "yellow".into(),
        text: note,
        emphasis: true,
    });
    // askpass can only answer yes/no, "yes" writes known_hosts
    request.ok = Some("Accept".into());
    request.cancel = Some("Reject".into());
    request
}

fn between<'a>(text: &'a str, start: &str, end: &str) -> Option<&'a str> {
    let from = text.find(start)? + start.len();
    let to = text[from..].find(end)? + from;
    Some(&text[from..to])
}

fn shorten_home(path: &str) -> String {
    match std::env::var("HOME") {
        Ok(home) if !home.is_empty() && path.starts_with(&home) => {
            format!("~{}", &path[home.len()..])
        }
        _ => path.to_string(),
    }
}

fn fingerprint(key: &str) -> Option<String> {
    let output = std::process::Command::new("ssh-keygen")
        .args(["-l", "-f", &format!("{key}.pub")])
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    // "256 SHA256:xxx comment (ED25519)"
    let text = String::from_utf8_lossy(&output.stdout);
    text.split_whitespace().nth(1).map(str::to_string)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_ssh_key_prompt() {
        assert_eq!(
            passphrase_key("Enter passphrase for key '/home/u/.ssh/id_ed25519': "),
            Some("/home/u/.ssh/id_ed25519".into())
        );
        assert_eq!(
            passphrase_key("Enter passphrase for /home/u/.ssh/id_rsa (me@host): "),
            Some("/home/u/.ssh/id_rsa".into())
        );
        assert_eq!(passphrase_key("user@host's password:"), None);
    }

    #[test]
    fn parses_host_key_prompt() {
        let prompt = "The authenticity of host 'build.lan (192.168.1.40)' can't be established.\n\
ED25519 key fingerprint is SHA256:Vb2x7kQe0rL9nM4pT1sYw8ZcH6uJ3fA5gD2iK7oP9qE.\n\
This key is not known by any other names.\n\
Are you sure you want to continue connecting (yes/no/[fingerprint])?";
        let request = build_request(prompt, "");
        assert_eq!(request.mode, "confirm");
        assert_eq!(request.details[0].1, "build.lan (192.168.1.40)");
        assert_eq!(request.details[1].1, "ED25519");
        assert_eq!(
            request.details[2].1,
            "SHA256:Vb2x7kQe0rL9nM4pT1sYw8ZcH6uJ3fA5gD2iK7oP9qE"
        );
        assert_eq!(
            request.notes[0].text,
            "First connection — not in ~/.ssh/known_hosts"
        );
    }

    #[test]
    fn user_presence_is_a_notice() {
        let request = build_request("Confirm user presence for key ED25519-SK SHA256:x", "none");
        assert_eq!(request.mode, "notice");
    }
}
