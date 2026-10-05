//! Secret Service access for the pinentry passphrase cache, same items as
//! pinentry-gnome3 (pinentry/password-cache.c): schema `org.gnupg.Passphrase`,
//! attributes `keygrip` (the raw SETKEYINFO value, e.g. `n/<grip>`) and
//! `stored-by`, label `GnuPG: <keygrip>`. Uses a plain session, the secret
//! never leaves the user's session bus.

use futures_util::StreamExt;
use std::collections::HashMap;
use std::time::Duration;
use zbus::zvariant::{ObjectPath, OwnedObjectPath, OwnedValue, Value};
use zbus::Connection;
use zeroize::Zeroize;

const BUS: &str = "org.freedesktop.secrets";
const SERVICE_PATH: &str = "/org/freedesktop/secrets";
const DEFAULT_COLLECTION: &str = "/org/freedesktop/secrets/aliases/default";
const SCHEMA: &str = "org.gnupg.Passphrase";
// unlocking may show a keyring prompt, give the user time
const TIMEOUT: Duration = Duration::from_secs(120);

type SecretStruct = (OwnedObjectPath, Vec<u8>, Vec<u8>, String);

pub fn lookup_gpg_passphrase(key_info: &str) -> Option<String> {
    block_on(lookup(key_info))
}

pub fn store_gpg_passphrase(key_info: &str, password: &str) {
    if block_on(store(key_info, password)).is_none() {
        eprintln!("shell-auth: could not save the passphrase in the keyring");
    }
}

fn block_on<F: std::future::Future<Output = Option<T>>, T>(future: F) -> Option<T> {
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .ok()?;
    runtime.block_on(async { tokio::time::timeout(TIMEOUT, future).await.ok().flatten() })
}

async fn open_session(connection: &Connection) -> Option<OwnedObjectPath> {
    let reply = connection
        .call_method(
            Some(BUS),
            SERVICE_PATH,
            Some("org.freedesktop.Secret.Service"),
            "OpenSession",
            &("plain", Value::from("")),
        )
        .await
        .ok()?;
    let (_, session): (OwnedValue, OwnedObjectPath) = reply.body().deserialize().ok()?;
    Some(session)
}

/// Complete a Secret Service prompt object ("/" means none needed).
async fn complete_prompt(connection: &Connection, prompt: &ObjectPath<'_>) -> Option<()> {
    if prompt.as_str() == "/" {
        return Some(());
    }
    let proxy = zbus::Proxy::new(
        connection,
        BUS,
        prompt.to_owned(),
        "org.freedesktop.Secret.Prompt",
    )
    .await
    .ok()?;
    let mut completed = proxy.receive_signal("Completed").await.ok()?;
    proxy.call_method("Prompt", &("",)).await.ok()?;
    let message = completed.next().await?;
    let (dismissed, _): (bool, OwnedValue) = message.body().deserialize().ok()?;
    (!dismissed).then_some(())
}

async fn lookup(key_info: &str) -> Option<String> {
    let connection = Connection::session().await.ok()?;
    let session = open_session(&connection).await?;
    let attributes = HashMap::from([("xdg:schema", SCHEMA), ("keygrip", key_info)]);
    let reply = connection
        .call_method(
            Some(BUS),
            SERVICE_PATH,
            Some("org.freedesktop.Secret.Service"),
            "SearchItems",
            &(attributes,),
        )
        .await
        .ok()?;
    let (unlocked, locked): (Vec<OwnedObjectPath>, Vec<OwnedObjectPath>) =
        reply.body().deserialize().ok()?;

    let item = match (unlocked.first(), locked.first()) {
        (Some(item), _) => item.clone(),
        (None, Some(item)) => {
            let reply = connection
                .call_method(
                    Some(BUS),
                    SERVICE_PATH,
                    Some("org.freedesktop.Secret.Service"),
                    "Unlock",
                    &(vec![item.clone()],),
                )
                .await
                .ok()?;
            let (_, prompt): (Vec<OwnedObjectPath>, OwnedObjectPath) =
                reply.body().deserialize().ok()?;
            complete_prompt(&connection, &prompt).await?;
            item.clone()
        }
        (None, None) => return None,
    };

    let reply = connection
        .call_method(
            Some(BUS),
            item.as_str(),
            Some("org.freedesktop.Secret.Item"),
            "GetSecret",
            &(session,),
        )
        .await
        .ok()?;
    let (_, _, mut value, _): SecretStruct = reply.body().deserialize().ok()?;
    let password = String::from_utf8(value.clone()).ok();
    value.zeroize();
    password
}

async fn store(key_info: &str, password: &str) -> Option<()> {
    let connection = Connection::session().await.ok()?;
    let session = open_session(&connection).await?;
    let attributes: HashMap<&str, &str> = HashMap::from([
        ("xdg:schema", SCHEMA),
        ("stored-by", "GnuPG Pinentry"),
        ("keygrip", key_info),
    ]);
    let label = format!("GnuPG: {key_info}");
    let properties: HashMap<&str, Value> = HashMap::from([
        (
            "org.freedesktop.Secret.Item.Label",
            Value::from(label.as_str()),
        ),
        (
            "org.freedesktop.Secret.Item.Attributes",
            Value::from(attributes),
        ),
    ]);
    let secret = (
        session,
        Vec::<u8>::new(),
        password.as_bytes().to_vec(),
        "text/plain",
    );
    let reply = connection
        .call_method(
            Some(BUS),
            DEFAULT_COLLECTION,
            Some("org.freedesktop.Secret.Collection"),
            "CreateItem",
            &(properties, secret, true),
        )
        .await
        .ok()?;
    let (_, prompt): (OwnedObjectPath, OwnedObjectPath) = reply.body().deserialize().ok()?;
    complete_prompt(&connection, &prompt).await
}
