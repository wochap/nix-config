//! Stock tools used when the shell socket is unreachable. Paths are baked in by
//! the nix package, plain names (resolved through PATH) otherwise.

use std::os::unix::process::CommandExt;
use std::process::Command;

pub const PINENTRY: &str = match option_env!("SHELL_AUTH_FALLBACK_PINENTRY") {
    Some(path) => path,
    None => "pinentry-gnome3",
};

pub const ASKPASS: &str = match option_env!("SHELL_AUTH_FALLBACK_ASKPASS") {
    Some(path) => path,
    None => "ssh-askpass",
};

/// Replace this process with `program`, returns only on failure.
pub fn exec(program: &str, args: &[String]) -> u8 {
    let error = Command::new(program).args(args).exec();
    eprintln!("shell-auth: failed to run fallback {program}: {error}");
    1
}
