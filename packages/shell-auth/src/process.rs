//! Requester info for the dialog footer.

use crate::socket::Requester;

/// Command line of `pid`, with the home directory shortened to `~`.
pub fn requester(pid: u32) -> Option<Requester> {
    if pid == 0 {
        return None;
    }
    let raw = std::fs::read(format!("/proc/{pid}/cmdline")).ok()?;
    let mut parts: Vec<String> = raw
        .split(|byte| *byte == 0)
        .filter(|part| !part.is_empty())
        .map(|part| String::from_utf8_lossy(part).into_owned())
        .collect();
    if parts.is_empty() {
        return None;
    }
    // nix store paths are noise, keep the program name
    if let Some(name) = parts[0].rsplit('/').next() {
        if parts[0].starts_with("/nix/store/") {
            parts[0] = name.to_string();
        }
    }
    let mut cmd = parts.join(" ");
    if let Some(home) = std::env::var_os("HOME").and_then(|home| home.into_string().ok()) {
        if !home.is_empty() {
            cmd = cmd.replace(&home, "~");
        }
    }
    const MAX_LEN: usize = 60;
    if cmd.chars().count() > MAX_LEN {
        cmd = cmd.chars().take(MAX_LEN - 1).collect::<String>() + "…";
    }
    Some(Requester { cmd, pid })
}
