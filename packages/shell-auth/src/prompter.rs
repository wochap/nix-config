//! gnome-keyring system prompter (`org.gnome.keyring.SystemPrompter`), the
//! service gcr-prompter normally provides. Protocol: gcr/org.gnome.keyring.Prompter.xml
//! and gcr/gcr-system-prompter.c in the gcr sources.
//!
//! Callers (gnome-keyring, gcr-ssh-agent, pinentry-gnome3) call BeginPrompting
//! with a callback object on their own connection, we answer PromptReady with
//! our secret exchange key, they call PerformPrompt with the prompt properties,
//! we show the quickshell dialog and answer PromptReady with the encrypted
//! password. StopPrompting ends the conversation.
//!
//! The name is owned only while the shell socket exists, otherwise D-Bus
//! activation falls back to the stock gcr-prompter.

use crate::exchange::Exchange;
use crate::socket::{self, Choice, Reply, Request};
use futures_util::StreamExt;
use std::collections::HashMap;
use std::os::unix::fs::{FileTypeExt, MetadataExt};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixStream;
use tokio::sync::mpsc;
use tokio::task::JoinHandle;
use zbus::fdo;
use zbus::fdo::{RequestNameFlags, RequestNameReply};
use zbus::message::Header;
use zbus::zvariant::{ObjectPath, OwnedValue, Value};
use zbus::{interface, Connection};
use zeroize::Zeroize;

const BUS_NAME: &str = "org.gnome.keyring.SystemPrompter";
const OBJECT_PATH: &str = "/org/gnome/keyring/Prompter";
const CALLBACK_INTERFACE: &str = "org.gnome.keyring.internal.Prompter.Callback";

/// (caller unique name, callback object path)
type Key = (String, String);

struct ActivePrompt {
    exchange: Exchange,
    /// prompt properties accumulate, callers only send what changed
    properties: HashMap<String, OwnedValue>,
    stream: Option<BufReader<UnixStream>>,
    task: Option<JoinHandle<()>>,
}

#[derive(Clone)]
struct Prompter {
    prompts: Arc<Mutex<HashMap<Key, ActivePrompt>>>,
    /// signals the shell socket failed, the name gets released
    socket_failed: mpsc::UnboundedSender<()>,
}

impl Prompter {
    fn remove(&self, key: &Key) -> bool {
        let prompt = self.prompts.lock().unwrap().remove(key);
        match prompt {
            Some(prompt) => {
                // dropping the stream closes the dialog
                if let Some(task) = prompt.task {
                    task.abort();
                }
                true
            }
            None => false,
        }
    }

    fn remove_caller(&self, caller: &str) {
        let keys: Vec<Key> = self
            .prompts
            .lock()
            .unwrap()
            .keys()
            .filter(|(name, _)| name == caller)
            .cloned()
            .collect();
        for key in keys {
            self.remove(&key);
        }
    }
}

fn sender(header: &Header<'_>) -> fdo::Result<String> {
    header
        .sender()
        .map(|sender| sender.to_string())
        .ok_or_else(|| fdo::Error::Failed("no sender".into()))
}

async fn prompt_ready(
    connection: &Connection,
    key: &Key,
    reply: &str,
    properties: HashMap<&str, Value<'_>>,
    exchange: String,
) -> zbus::Result<()> {
    connection
        .call_method(
            Some(key.0.as_str()),
            key.1.as_str(),
            Some(CALLBACK_INTERFACE),
            "PromptReady",
            &(reply, properties, exchange),
        )
        .await
        .map(|_| ())
}

#[interface(name = "org.gnome.keyring.internal.Prompter")]
impl Prompter {
    async fn begin_prompting(
        &self,
        #[zbus(header)] header: Header<'_>,
        #[zbus(connection)] connection: &Connection,
        callback: ObjectPath<'_>,
    ) -> fdo::Result<()> {
        let key: Key = (sender(&header)?, callback.to_string());
        let exchange = Exchange::new();
        let begin = exchange.begin();
        {
            let mut prompts = self.prompts.lock().unwrap();
            if prompts.contains_key(&key) {
                return Err(fdo::Error::Failed(
                    "Already begun prompting for this prompt callback".into(),
                ));
            }
            prompts.insert(
                key.clone(),
                ActivePrompt {
                    exchange,
                    properties: HashMap::new(),
                    stream: None,
                    task: None,
                },
            );
        }
        // every caller gets its own dialog connection, the shell queues them
        let this = self.clone();
        let connection = connection.clone();
        tokio::spawn(async move {
            if prompt_ready(&connection, &key, "", HashMap::new(), begin)
                .await
                .is_err()
            {
                this.remove(&key);
            }
        });
        Ok(())
    }

    async fn perform_prompt(
        &self,
        #[zbus(header)] header: Header<'_>,
        #[zbus(connection)] connection: &Connection,
        callback: ObjectPath<'_>,
        kind: String,
        properties: HashMap<String, OwnedValue>,
        exchange: String,
    ) -> fdo::Result<()> {
        let key: Key = (sender(&header)?, callback.to_string());
        if kind != "password" && kind != "confirm" {
            return Err(fdo::Error::InvalidArgs("Invalid type argument".into()));
        }

        let request = {
            let mut prompts = self.prompts.lock().unwrap();
            let prompt = prompts.get_mut(&key).ok_or_else(|| {
                fdo::Error::Failed("Not begun prompting for this prompt callback".into())
            })?;
            if prompt.task.as_ref().is_some_and(|task| !task.is_finished()) {
                return Err(fdo::Error::Failed(
                    "Already performing a prompt for this prompt callback".into(),
                ));
            }
            prompt.properties.extend(properties);
            prompt
                .exchange
                .receive(&exchange)
                .map_err(|_| fdo::Error::InvalidArgs("Invalid secret exchange received".into()))?;
            build_request(&kind, &prompt.properties)
        };

        let this = self.clone();
        let connection = connection.clone();
        let task_key = key.clone();
        let task =
            tokio::spawn(async move { this.show(connection, task_key, kind, request).await });
        if let Some(prompt) = self.prompts.lock().unwrap().get_mut(&key) {
            prompt.task = Some(task);
        }
        Ok(())
    }

    async fn stop_prompting(
        &self,
        #[zbus(header)] header: Header<'_>,
        #[zbus(connection)] connection: &Connection,
        callback: ObjectPath<'_>,
    ) -> fdo::Result<()> {
        let key: Key = (sender(&header)?, callback.to_string());
        if self.remove(&key) {
            let connection = connection.clone();
            tokio::spawn(async move {
                let _ = connection
                    .call_method(
                        Some(key.0.as_str()),
                        key.1.as_str(),
                        Some(CALLBACK_INTERFACE),
                        "PromptDone",
                        &(),
                    )
                    .await;
            });
        }
        Ok(())
    }
}

impl Prompter {
    /// Show one prompt in the shell and send the answer back to the caller.
    async fn show(self, connection: Connection, key: Key, kind: String, request: Request) {
        let stream = self
            .prompts
            .lock()
            .unwrap()
            .get_mut(&key)
            .and_then(|prompt| prompt.stream.take());
        let stream = match stream {
            Some(stream) => Some(stream),
            None => match socket::socket_path() {
                Some(path) => UnixStream::connect(path).await.ok().map(BufReader::new),
                None => None,
            },
        };

        let (reply, stream) = match stream {
            Some(stream) => ask(stream, &request).await,
            None => {
                let _ = self.socket_failed.send(());
                (Reply::cancelled(), None)
            }
        };

        let is_password = kind == "password";
        let mut changed: HashMap<&str, Value> = HashMap::new();
        // gcr-system-prompter.c sends these double wrapped (g_variant_new_variant
        // inside a{sv}) and the client unwraps them with g_variant_get_variant
        if request.choice.is_some() {
            changed.insert(
                "choice-chosen",
                Value::Value(Box::new(Value::from(reply.choice))),
            );
        }
        if request.mode == "new-password" {
            changed.insert(
                "password-strength",
                Value::Value(Box::new(Value::from(reply.strength))),
            );
        }

        let message = {
            let mut prompts = self.prompts.lock().unwrap();
            let Some(prompt) = prompts.get_mut(&key) else {
                return;
            };
            prompt.stream = stream;
            let secret = (reply.is_ok() && is_password).then_some(reply.password.as_bytes());
            match prompt.exchange.send(secret) {
                Ok(message) => message,
                Err(_) => return,
            }
        };
        let response = if reply.is_ok() { "yes" } else { "no" };
        if prompt_ready(&connection, &key, response, changed, message)
            .await
            .is_err()
        {
            self.remove(&key);
        }
    }
}

/// Send `request` and wait for one reply line, EOF counts as cancel.
async fn ask(
    mut stream: BufReader<UnixStream>,
    request: &Request,
) -> (Reply, Option<BufReader<UnixStream>>) {
    if stream
        .get_mut()
        .write_all(request.to_line().as_bytes())
        .await
        .is_err()
    {
        return (Reply::cancelled(), None);
    }
    let mut line = String::new();
    let reply = match stream.read_line(&mut line).await {
        Ok(read) if read > 0 => Reply::parse(line.trim_end()),
        _ => return (Reply::cancelled(), None),
    };
    line.zeroize();
    (reply, Some(stream))
}

fn text(properties: &HashMap<String, OwnedValue>, name: &str) -> String {
    properties
        .get(name)
        .and_then(|value| <&str>::try_from(&**value).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

fn flag(properties: &HashMap<String, OwnedValue>, name: &str) -> bool {
    properties
        .get(name)
        .and_then(|value| bool::try_from(&**value).ok())
        .unwrap_or(false)
}

fn label(text: String) -> Option<String> {
    let text = text.replace('_', "");
    (!text.is_empty()).then_some(text)
}

/// gnome-keyring texts, e.g. title "Unlock Keyring", message "Authentication
/// required", description "An application wants access to the keyring “Work”, but it is locked".
fn build_request(kind: &str, properties: &HashMap<String, OwnedValue>) -> Request {
    let title = text(properties, "title");
    let message = text(properties, "message");
    let description = text(properties, "description");
    let is_new = kind == "password" && flag(properties, "password-new");
    let is_ssh = format!("{title} {message} {description}")
        .to_lowercase()
        .contains("private key");

    let mode = match kind {
        "confirm" => "confirm",
        _ if is_new => "new-password",
        _ => "password",
    };
    let mut request = Request::new(if is_ssh { "ssh" } else { "gnome-keyring" }, mode);
    request.title = [&title, &message]
        .into_iter()
        .find(|t| !t.is_empty())
        .cloned()
        .unwrap_or_else(|| "Authentication required".into());
    request.message = if description.is_empty() && request.title != message {
        message
    } else {
        description.clone()
    };

    // the keyring or key name is quoted in the description
    if let Some(name) = description
        .split('“')
        .nth(1)
        .and_then(|rest| rest.split('”').next())
    {
        let field = if is_ssh { "Key" } else { "Keyring" };
        request.details.push((field.into(), name.to_string(), true));
    }
    if is_ssh {
        request.prompt = Some("Passphrase".into());
    }

    let warning = text(properties, "warning");
    if !warning.is_empty() {
        request.error = Some(warning);
    }
    if let Some(choice) = label(text(properties, "choice-label")) {
        request.choice = Some(Choice {
            label: choice,
            checked: flag(properties, "choice-chosen"),
        });
    }
    request.ok = label(text(properties, "continue-label")).or_else(|| {
        Some(match mode {
            "confirm" => "Continue".into(),
            "new-password" => "Create".into(),
            _ => "Unlock".into(),
        })
    });
    request.cancel = label(text(properties, "cancel-label"));
    request
}

/// Socket file identity, a new inode means the shell restarted.
fn socket_inode() -> Option<u64> {
    let metadata = std::fs::metadata(socket::socket_path()?).ok()?;
    metadata.file_type().is_socket().then_some(metadata.ino())
}

async fn serve() -> zbus::Result<()> {
    let (socket_failed, mut failures) = mpsc::unbounded_channel();
    let prompter = Prompter {
        prompts: Arc::new(Mutex::new(HashMap::new())),
        socket_failed,
    };
    let connection = zbus::connection::Builder::session()?
        .serve_at(OBJECT_PATH, prompter.clone())?
        .build()
        .await?;

    // forget prompts of callers that left the bus
    let dbus = fdo::DBusProxy::new(&connection).await?;
    let mut owner_changes = dbus.receive_name_owner_changed().await?;
    let watcher = prompter.clone();
    tokio::spawn(async move {
        while let Some(signal) = owner_changes.next().await {
            if let Ok(args) = signal.args() {
                if args.new_owner().is_none() && args.name().starts_with(':') {
                    watcher.remove_caller(args.name());
                }
            }
        }
    });

    // own the name while the shell socket is up; a failed connect marks the
    // current socket file as dead until the shell recreates it
    let mut is_owner = false;
    let mut dead_inode: Option<u64> = None;
    let mut tick = tokio::time::interval(Duration::from_secs(1));
    loop {
        tokio::select! {
            _ = tick.tick() => {}
            Some(()) = failures.recv() => dead_inode = socket_inode(),
        }
        let inode = socket_inode();
        let is_alive = inode.is_some() && inode != dead_inode;
        if is_alive && !is_owner {
            // no AllowReplacement: a stray gcr-prompter activation must not steal it
            let flags = RequestNameFlags::ReplaceExisting | RequestNameFlags::DoNotQueue;
            if let Ok(RequestNameReply::PrimaryOwner | RequestNameReply::AlreadyOwner) = dbus
                .request_name(BUS_NAME.try_into().expect("valid name"), flags)
                .await
            {
                is_owner = true;
            }
        } else if !is_alive && is_owner {
            let _ = dbus
                .release_name(BUS_NAME.try_into().expect("valid name"))
                .await;
            is_owner = false;
        }
    }
}

pub fn run() -> u8 {
    let runtime = match tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
    {
        Ok(runtime) => runtime,
        Err(error) => {
            eprintln!("shell-auth: {error}");
            return 1;
        }
    };
    match runtime.block_on(serve()) {
        Ok(()) => 0,
        Err(error) => {
            eprintln!("shell-auth: {error}");
            1
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn props(entries: &[(&str, Value<'static>)]) -> HashMap<String, OwnedValue> {
        entries
            .iter()
            .map(|(name, value)| {
                (
                    name.to_string(),
                    OwnedValue::try_from(value.try_clone().unwrap()).unwrap(),
                )
            })
            .collect()
    }

    #[test]
    fn maps_keyring_unlock() {
        let properties = props(&[
            ("title", Value::from("Unlock Keyring")),
            ("message", Value::from("Authentication required")),
            (
                "description",
                Value::from("An application wants access to the keyring “Work”, but it is locked"),
            ),
            (
                "choice-label",
                Value::from("Automatically unlock this keyring whenever I’m logged in"),
            ),
            ("continue-label", Value::from("Unlock")),
        ]);
        let request = build_request("password", &properties);
        assert_eq!(request.source, "gnome-keyring");
        assert_eq!(request.title, "Unlock Keyring");
        assert_eq!(request.details[0].1, "Work");
        assert!(request.choice.is_some());
    }

    #[test]
    fn maps_ssh_key_and_new_password() {
        let properties = props(&[
            ("title", Value::from("Unlock private key")),
            (
                "description",
                Value::from(
                    "An application wants access to the private key “id_ed25519”, but it is locked",
                ),
            ),
        ]);
        assert_eq!(build_request("password", &properties).source, "ssh");
        let properties = props(&[
            ("title", Value::from("New Keyring Password")),
            ("password-new", Value::from(true)),
        ]);
        assert_eq!(build_request("password", &properties).mode, "new-password");
    }
}
