//! JSON lines protocol shared with `services/SAuth.qml`.
//!
//! The client sends `{"type":"prompt",...}` and reads one reply line per prompt.
//! A connection may carry several prompts (retries after a wrong password); the
//! dialog stays open in a "verifying" state until the next prompt arrives or
//! the connection closes. `{"type":"close"}` or EOF dismisses it.

use serde::{Deserialize, Serialize};
use std::io::{self, BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use zeroize::Zeroize;

pub fn socket_path() -> Option<PathBuf> {
    let runtime_dir = std::env::var_os("XDG_RUNTIME_DIR")?;
    Some(PathBuf::from(runtime_dir).join("quickshell-auth.sock"))
}

#[derive(Serialize, Clone, Debug)]
pub struct Choice {
    pub label: String,
    pub checked: bool,
}

#[derive(Serialize, Clone, Debug)]
pub struct Note {
    pub icon: String,
    pub tint: String,
    pub text: String,
    pub emphasis: bool,
}

#[derive(Serialize, Clone, Debug)]
pub struct Requester {
    pub cmd: String,
    pub pid: u32,
}

#[derive(Serialize, Clone, Debug)]
pub struct Request {
    #[serde(rename = "type")]
    pub kind: &'static str,
    pub source: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tint: Option<String>,
    pub title: String,
    pub message: String,
    /// (label, value, is_mono)
    pub details: Vec<(String, String, bool)>,
    pub notes: Vec<Note>,
    /// password | new-password | confirm | notice
    pub mode: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub choice: Option<Choice>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ok: Option<String>,
    /// an empty label hides the cancel button
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cancel: Option<String>,
    #[serde(skip_serializing_if = "is_zero")]
    pub timeout: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub requester: Option<Requester>,
}

fn is_zero(value: &u32) -> bool {
    *value == 0
}

impl Request {
    pub fn new(source: &str, mode: &'static str) -> Self {
        Self {
            kind: "prompt",
            source: source.to_string(),
            icon: None,
            tint: None,
            title: String::new(),
            message: String::new(),
            details: Vec::new(),
            notes: Vec::new(),
            mode,
            prompt: None,
            error: None,
            choice: None,
            ok: None,
            cancel: None,
            timeout: 0,
            requester: None,
        }
    }

    pub fn to_line(&self) -> String {
        let mut line = serde_json::to_string(self).expect("request serializes");
        line.push('\n');
        line
    }
}

#[derive(Deserialize, Default)]
pub struct Reply {
    /// ok | cancel | timeout
    pub result: String,
    #[serde(default)]
    pub password: String,
    #[serde(default)]
    pub choice: bool,
    #[serde(default)]
    pub strength: i32,
}

impl Reply {
    pub fn cancelled() -> Self {
        Self {
            result: "cancel".to_string(),
            password: String::new(),
            choice: false,
            strength: 0,
        }
    }

    pub fn parse(line: &str) -> Self {
        serde_json::from_str(line).unwrap_or_else(|_| Self::cancelled())
    }

    pub fn is_ok(&self) -> bool {
        self.result == "ok"
    }
}

impl Drop for Reply {
    fn drop(&mut self) {
        self.password.zeroize();
    }
}

/// Blocking client used by pinentry and askpass.
pub struct Client {
    writer: UnixStream,
    reader: BufReader<UnixStream>,
}

impl Client {
    pub fn connect() -> io::Result<Self> {
        let path = socket_path()
            .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "XDG_RUNTIME_DIR not set"))?;
        let writer = UnixStream::connect(path)?;
        let reader = BufReader::new(writer.try_clone()?);
        Ok(Self { writer, reader })
    }

    /// Show `request` and wait for the answer, a closed connection counts as cancel.
    pub fn prompt(&mut self, request: &Request) -> io::Result<Reply> {
        self.writer.write_all(request.to_line().as_bytes())?;
        self.writer.flush()?;
        let mut line = String::new();
        let read = self.reader.read_line(&mut line)?;
        let reply = if read == 0 {
            Reply::cancelled()
        } else {
            Reply::parse(line.trim_end())
        };
        line.zeroize();
        Ok(reply)
    }

    /// Show `request` without expecting an answer (ssh user presence notice).
    pub fn show(&mut self, request: &Request) -> io::Result<()> {
        self.writer.write_all(request.to_line().as_bytes())?;
        self.writer.flush()
    }

    /// Block until the shell closes the connection or answers.
    pub fn wait(&mut self) {
        let mut line = String::new();
        let _ = self.reader.read_line(&mut line);
    }

    pub fn close(&mut self) {
        let _ = self.writer.write_all(b"{\"type\":\"close\"}\n");
        let _ = self.writer.flush();
    }
}
