//! Multi-call binary that forwards auth prompts to the quickshell auth dialog
//! (`services/SAuth.qml`) over `$XDG_RUNTIME_DIR/quickshell-auth.sock`.
//!
//! - `shell-auth pinentry` (or `pinentry-shell`): gpg-agent pinentry
//! - `shell-auth askpass <prompt>` (or `shell-askpass`): ssh askpass
//! - `shell-auth prompter`: gnome-keyring system prompter D-Bus service
//!
//! When the shell socket is unreachable each mode falls back to the stock tool.

mod askpass;
mod exchange;
mod fallback;
mod pinentry;
mod process;
mod prompter;
mod secrets;
mod socket;

use std::path::Path;
use std::process::ExitCode;

fn usage() -> ExitCode {
    eprintln!("usage: shell-auth <pinentry|askpass PROMPT|prompter>");
    ExitCode::from(2)
}

fn main() -> ExitCode {
    let mut args: Vec<String> = std::env::args().collect();
    let argv0 = args.remove(0);
    let program = Path::new(&argv0)
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or_default();

    let mode = match program {
        "pinentry-shell" => "pinentry".to_string(),
        "shell-askpass" => "askpass".to_string(),
        _ if args.is_empty() => return usage(),
        _ => args.remove(0),
    };

    let code = match mode.as_str() {
        "pinentry" => pinentry::run(args),
        "askpass" => askpass::run(args),
        "prompter" => prompter::run(),
        _ => return usage(),
    };
    ExitCode::from(code)
}
