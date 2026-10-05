//! gpg-agent pinentry speaking the Assuan protocol on stdin/stdout, see
//! pinentry/pinentry.c in the pinentry sources for the reference behaviour.

use crate::fallback;
use crate::process;
use crate::secrets;
use crate::socket::{Choice, Client, Request};
use std::io::{self, BufRead, Write};
use zeroize::Zeroize;

// gpg_error(code) with GPG_ERR_SOURCE_PINENTRY (5)
const ERR_CANCELED: &str = "ERR 83886179 Operation cancelled";
const ERR_TIMEOUT: &str = "ERR 83886142 Timeout";
const ERR_NOT_CONFIRMED: &str = "ERR 83886194 Not confirmed";
const ERR_UNKNOWN_COMMAND: &str = "ERR 536871187 Unknown IPC command";

#[derive(Default)]
struct State {
    description: String,
    prompt: String,
    title: String,
    error: String,
    ok: String,
    cancel: String,
    not_ok: String,
    repeat: bool,
    key_info: String,
    timeout: u32,
    owner_pid: u32,
    allow_external_cache: bool,
    tried_cache: bool,
}

pub fn run(args: Vec<String>) -> u8 {
    // decide before touching stdin so the fallback gets the whole conversation
    let mut client = match Client::connect() {
        Ok(client) => client,
        Err(_) => return fallback::exec(fallback::PINENTRY, &args),
    };

    let stdin = io::stdin();
    let mut out = io::stdout().lock();
    let mut state = State::default();
    let _ = writeln!(
        out,
        "OK Pleased to meet you, process {}",
        std::process::id()
    );
    let _ = out.flush();

    for line in stdin.lock().lines() {
        let Ok(line) = line else { break };
        let (command, argument) = match line.split_once(' ') {
            Some((command, argument)) => (command.to_ascii_uppercase(), unescape(argument)),
            None => (line.to_ascii_uppercase(), String::new()),
        };

        let response: Vec<String> = match command.as_str() {
            "OPTION" => {
                option(&mut state, &argument);
                vec!["OK".into()]
            }
            "SETDESC" => set(&mut state.description, argument),
            "SETPROMPT" => set(&mut state.prompt, argument),
            "SETTITLE" => set(&mut state.title, argument),
            "SETERROR" => set(&mut state.error, argument),
            "SETOK" => set(&mut state.ok, argument),
            "SETCANCEL" => set(&mut state.cancel, argument),
            "SETNOTOK" => set(&mut state.not_ok, argument),
            "SETKEYINFO" => {
                state.key_info = if argument == "--clear" {
                    String::new()
                } else {
                    argument
                };
                vec!["OK".into()]
            }
            "SETREPEAT" => {
                state.repeat = true;
                vec!["OK".into()]
            }
            "SETTIMEOUT" => {
                state.timeout = argument.trim().parse().unwrap_or(0);
                vec!["OK".into()]
            }
            "SETREPEATERROR" | "SETREPEATOK" | "SETQUALITYBAR" | "SETQUALITYBAR_TT"
            | "SETGENPIN" | "SETGENPIN_TT" | "NOP" | "CLEARPASSPHRASE" => vec!["OK".into()],
            "GETPIN" => get_pin(&mut state, &mut client),
            "CONFIRM" => confirm(&mut state, &mut client, argument.contains("--one-button")),
            "MESSAGE" => confirm(&mut state, &mut client, true),
            "GETINFO" => get_info(&argument),
            "RESET" => {
                state = State::default();
                vec!["OK".into()]
            }
            "BYE" => {
                let _ = writeln!(out, "OK closing connection");
                let _ = out.flush();
                break;
            }
            _ => vec![ERR_UNKNOWN_COMMAND.into()],
        };

        for mut reply in response {
            let _ = writeln!(out, "{reply}");
            reply.zeroize();
        }
        let _ = out.flush();
    }

    client.close();
    0
}

fn set(field: &mut String, value: String) -> Vec<String> {
    *field = value;
    vec!["OK".into()]
}

fn option(state: &mut State, argument: &str) {
    let (key, value) = argument.split_once('=').unwrap_or((argument, ""));
    match key.trim() {
        "allow-external-password-cache" => state.allow_external_cache = true,
        // "owner=PID/UID HOST"
        "owner" => {
            state.owner_pid = value
                .split(['/', ' '])
                .next()
                .and_then(|pid| pid.parse().ok())
                .unwrap_or(0)
        }
        _ => {}
    }
}

fn get_info(argument: &str) -> Vec<String> {
    let value = match argument.trim() {
        "pid" => std::process::id().to_string(),
        "version" => env!("CARGO_PKG_VERSION").to_string(),
        "flavor" => "shell".to_string(),
        "ttyinfo" => "- - -".to_string(),
        _ => return vec!["ERR 83886360 IPC parameter error".into()],
    };
    vec![format!("D {}", escape(&value)), "OK".into()]
}

fn get_pin(state: &mut State, client: &mut Client) -> Vec<String> {
    let may_cache = state.allow_external_cache && !state.key_info.is_empty();

    // pinentry-gnome3 compatible cache: tried once per process, skipped after an error
    if may_cache && !state.repeat && !state.tried_cache && state.error.is_empty() {
        state.tried_cache = true;
        if let Some(mut password) = secrets::lookup_gpg_passphrase(&state.key_info) {
            let response = vec![
                "S PASSWORD_FROM_CACHE".into(),
                format!("D {}", escape(&password)),
                "OK".into(),
            ];
            password.zeroize();
            return response;
        }
    }

    let mut request = gpg_request(state);
    request.mode = if state.repeat {
        "new-password"
    } else {
        "password"
    };
    request.prompt = Some(clean_label(&state.prompt).unwrap_or_else(|| "Passphrase".into()));
    if may_cache && !state.repeat {
        request.choice = Some(Choice {
            label: "Save in keyring".into(),
            checked: false,
        });
    }

    let reply = client.prompt(&request);
    state.error.clear();
    state.repeat = false;
    let Ok(reply) = reply else {
        return vec![ERR_CANCELED.into()];
    };
    match reply.result.as_str() {
        "ok" => {
            if may_cache && reply.choice {
                secrets::store_gpg_passphrase(&state.key_info, &reply.password);
            }
            let mut response = Vec::new();
            if request.mode == "new-password" {
                response.push("S PIN_REPEATED".into());
            }
            if !reply.password.is_empty() {
                response.push(format!("D {}", escape(&reply.password)));
            }
            response.push("OK".into());
            response
        }
        "timeout" => vec![ERR_TIMEOUT.into()],
        _ => vec![ERR_CANCELED.into()],
    }
}

fn confirm(state: &mut State, client: &mut Client, one_button: bool) -> Vec<String> {
    let mut request = gpg_request(state);
    request.mode = "confirm";
    request.title = clean_label(&state.title).unwrap_or_else(|| "Confirm".into());
    request.ok = Some(clean_label(&state.ok).unwrap_or_else(|| "OK".into()));
    request.cancel = Some(if one_button {
        String::new()
    } else {
        clean_label(&state.cancel)
            .or_else(|| clean_label(&state.not_ok))
            .unwrap_or_else(|| "Cancel".into())
    });

    let reply = client.prompt(&request);
    state.error.clear();
    match reply {
        Ok(reply) if reply.is_ok() => vec!["OK".into()],
        Ok(reply) if reply.result == "timeout" => vec![ERR_TIMEOUT.into()],
        // with a "not ok" button and no cancel label, gpg-agent expects NOT_CONFIRMED
        _ if !state.not_ok.is_empty() && state.cancel.is_empty() => vec![ERR_NOT_CONFIRMED.into()],
        _ => vec![ERR_CANCELED.into()],
    }
}

/// Fields shared by every prompt, the description is split into message + details.
fn gpg_request(state: &State) -> Request {
    let mut request = Request::new("gpg-agent", "password");
    let (message, details) = parse_description(&state.description);
    request.title = clean_label(&state.title).unwrap_or_else(|| {
        if state.repeat {
            "Create passphrase".into()
        } else if state.description.contains("OpenPGP") {
            "Unlock OpenPGP key".into()
        } else {
            "Passphrase required".into()
        }
    });
    request.message = message;
    request.details = details;
    if !state.error.is_empty() {
        request.error = Some(state.error.clone());
    }
    request.ok = clean_label(&state.ok).or_else(|| {
        Some(if state.repeat {
            "Create".into()
        } else {
            "Unlock".into()
        })
    });
    request.cancel = clean_label(&state.cancel);
    request.timeout = state.timeout;
    request.requester = process::requester(state.owner_pid);
    request
}

/// gpg-agent sends e.g.
/// `Please enter the passphrase to unlock the OpenPGP secret key:\n"Jane <j@x>"\n255-bit EDDSA key, ID 9F2C41A87B3ED0C4,\ncreated 2025-03-14.\n`
fn parse_description(description: &str) -> (String, Vec<(String, String, bool)>) {
    let mut message_lines = Vec::new();
    let mut details = Vec::new();
    for line in description
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
    {
        if line.starts_with('"') && line.ends_with('"') && line.len() > 1 {
            details.push(("User ID".into(), line[1..line.len() - 1].to_string(), false));
        } else if let Some((algorithm, id)) = line.split_once(" key, ID ") {
            let id = id.trim_end_matches(',').trim_end_matches('.');
            let id = id.split(" (").next().unwrap_or(id);
            details.push((
                "Key ID".into(),
                format!("{} / {}", algorithm, group(id)),
                true,
            ));
        } else if let Some(created) = line.strip_prefix("created ") {
            let created = created.trim_end_matches('.');
            let created = created.split(" (").next().unwrap_or(created);
            details.push(("Created".into(), created.to_string(), false));
        } else {
            message_lines.push(line);
        }
    }
    let mut message = message_lines.join(" ");
    if message.ends_with(':') {
        message.pop();
        message.push('.');
    }
    (message, details)
}

/// 9F2C41A87B3ED0C4 -> 9F2C 41A8 7B3E D0C4
fn group(id: &str) -> String {
    id.chars()
        .collect::<Vec<_>>()
        .chunks(4)
        .map(|chunk| chunk.iter().collect::<String>())
        .collect::<Vec<_>>()
        .join(" ")
}

/// Drop mnemonic underscores and trailing colons from gpg-agent labels.
fn clean_label(label: &str) -> Option<String> {
    let label = label.trim().trim_end_matches(':').replace('_', "");
    (!label.is_empty()).then_some(label)
}

fn unescape(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            let hex = std::str::from_utf8(&bytes[i + 1..i + 3]).unwrap_or("");
            if let Ok(byte) = u8::from_str_radix(hex, 16) {
                out.push(byte);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn escape(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in text.chars() {
        match c {
            '%' => out.push_str("%25"),
            '\r' => out.push_str("%0D"),
            '\n' => out.push_str("%0A"),
            _ => out.push(c),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unescapes_assuan() {
        assert_eq!(unescape("a%0Ab%25c"), "a\nb%c");
        assert_eq!(unescape("100%"), "100%");
        assert_eq!(escape("a\nb%c"), "a%0Ab%25c");
    }

    #[test]
    fn parses_gpg_description() {
        let description = "Please enter the passphrase to unlock the OpenPGP secret key:\n\"Jane Doe <jane@example.org>\"\n255-bit EDDSA key, ID 9F2C41A87B3ED0C4,\ncreated 2025-03-14 (main key ID 1111222233334444).\n";
        let (message, details) = parse_description(description);
        assert_eq!(
            message,
            "Please enter the passphrase to unlock the OpenPGP secret key."
        );
        assert_eq!(
            details[0],
            (
                "User ID".into(),
                "Jane Doe <jane@example.org>".into(),
                false
            )
        );
        assert_eq!(
            details[1],
            (
                "Key ID".into(),
                "255-bit EDDSA / 9F2C 41A8 7B3E D0C4".into(),
                true
            )
        );
        assert_eq!(details[2], ("Created".into(), "2025-03-14".into(), false));
    }

    #[test]
    fn cleans_labels() {
        assert_eq!(clean_label("_OK"), Some("OK".into()));
        assert_eq!(clean_label("Passphrase:"), Some("Passphrase".into()));
        assert_eq!(clean_label("  "), None);
    }
}
