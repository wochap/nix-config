//! gcr secret exchange, protocol `sx-aes-1` (gcr/gcr-secret-exchange.c):
//! DH over the IKE 1536-bit MODP group, transport key = HKDF-SHA256(shared
//! secret, zero salt, no info) truncated to 16 bytes, AES-128-CBC with PKCS7
//! padding. Big numbers are unsigned big-endian without leading zeros.
//! Messages are GKeyFile groups:
//!
//! ```text
//! [sx-aes-1]
//! public=<base64>
//! secret=<base64>
//! iv=<base64>
//! ```

use aes::cipher::{block_padding::Pkcs7, BlockDecryptMut, BlockEncryptMut, KeyIvInit};
use base64::{engine::general_purpose::STANDARD, Engine};
use hkdf::Hkdf;
use num_bigint::BigUint;
use sha2::Sha256;
use zeroize::Zeroizing;

const PROTOCOL: &str = "sx-aes-1";

// RFC 2409 / RFC 3526 group 5 ("ietf-ike-grp-modp-1536"), generator 2
const PRIME_HEX: &str = concat!(
    "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1",
    "29024E088A67CC74020BBEA63B139B22514A08798E3404DD",
    "EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245",
    "E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED",
    "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D",
    "C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F",
    "83655D23DCA3AD961C62F356208552BB9ED529077096966D",
    "670C354E4ABC9804F1746C08CA237327FFFFFFFFFFFFFFFF",
);

type Aes128CbcEnc = cbc::Encryptor<aes::Aes128>;
type Aes128CbcDec = cbc::Decryptor<aes::Aes128>;

fn prime() -> BigUint {
    BigUint::parse_bytes(PRIME_HEX.as_bytes(), 16).expect("valid prime")
}

pub struct Exchange {
    private: BigUint,
    public: Vec<u8>,
    key: Option<Zeroizing<[u8; 16]>>,
}

impl Exchange {
    pub fn new() -> Self {
        let prime = prime();
        let bits = prime.bits() as usize;
        // random exponent below the prime, like egg_dh_gen_pair
        let mut bytes = Zeroizing::new(vec![0u8; bits.div_ceil(8)]);
        getrandom::getrandom(&mut bytes).expect("system randomness");
        bytes[0] &= 0x7f;
        let private = BigUint::from_bytes_be(&bytes) | BigUint::from(1u8);
        let public = BigUint::from(2u8).modpow(&private, &prime).to_bytes_be();
        Self {
            private,
            public,
            key: None,
        }
    }

    /// First message, our public key only.
    pub fn begin(&self) -> String {
        format!("[{PROTOCOL}]\npublic={}\n", STANDARD.encode(&self.public))
    }

    /// Parse the peer's message, derive the transport key on first use and
    /// return the decrypted secret if the message carries one.
    pub fn receive(&mut self, message: &str) -> Result<Option<Zeroizing<Vec<u8>>>, String> {
        let fields = parse(message)?;
        if self.key.is_none() {
            let peer = fields.public.ok_or("missing public key")?;
            self.derive(&peer)?;
        }
        let (Some(secret), Some(iv)) = (fields.secret, fields.iv) else {
            return Ok(None);
        };
        let key = self.key.as_ref().ok_or("no transport key")?;
        if iv.len() != 16 {
            return Err("invalid iv".into());
        }
        let plain = Aes128CbcDec::new(key.as_slice().into(), iv.as_slice().into())
            .decrypt_padded_vec_mut::<Pkcs7>(&secret)
            .map_err(|_| "invalid padding")?;
        Ok(Some(Zeroizing::new(plain)))
    }

    /// Reply message, optionally carrying an encrypted secret.
    pub fn send(&self, secret: Option<&[u8]>) -> Result<String, String> {
        let mut message = self.begin();
        if let Some(secret) = secret {
            let key = self
                .key
                .as_ref()
                .ok_or("receive() must run before send()")?;
            let mut iv = [0u8; 16];
            getrandom::getrandom(&mut iv).map_err(|e| e.to_string())?;
            let cipher = Aes128CbcEnc::new(key.as_slice().into(), (&iv).into())
                .encrypt_padded_vec_mut::<Pkcs7>(secret);
            message.push_str(&format!(
                "secret={}\niv={}\n",
                STANDARD.encode(cipher),
                STANDARD.encode(iv)
            ));
        }
        Ok(message)
    }

    fn derive(&mut self, peer: &[u8]) -> Result<(), String> {
        let prime = prime();
        let peer = BigUint::from_bytes_be(peer);
        if peer <= BigUint::from(1u8) || peer >= prime {
            return Err("invalid peer public key".into());
        }
        let shared = Zeroizing::new(peer.modpow(&self.private, &prime).to_bytes_be());
        let mut key = Zeroizing::new([0u8; 16]);
        Hkdf::<Sha256>::new(None, &shared)
            .expand(&[], key.as_mut_slice())
            .map_err(|_| "hkdf")?;
        self.key = Some(key);
        Ok(())
    }
}

#[derive(Default)]
struct Fields {
    public: Option<Vec<u8>>,
    secret: Option<Vec<u8>>,
    iv: Option<Vec<u8>>,
}

fn parse(message: &str) -> Result<Fields, String> {
    let mut fields = Fields::default();
    let mut in_group = false;
    for line in message.lines().map(str::trim) {
        if line.starts_with('[') {
            in_group = line == format!("[{PROTOCOL}]");
            continue;
        }
        if !in_group {
            continue;
        }
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let decoded = || {
            STANDARD
                .decode(value.trim())
                .map_err(|_| format!("invalid base64 in {key}"))
        };
        match key.trim() {
            "public" => fields.public = Some(decoded()?),
            "secret" => fields.secret = Some(decoded()?),
            "iv" => fields.iv = Some(decoded()?),
            _ => {}
        }
    }
    if fields.public.is_none() && fields.secret.is_none() {
        return Err(format!("not a {PROTOCOL} message"));
    }
    Ok(fields)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip() {
        let mut client = Exchange::new();
        let mut prompter = Exchange::new();
        // prompter begins, client receives and answers with its own key
        assert!(client.receive(&prompter.begin()).unwrap().is_none());
        let request = client.send(None).unwrap();
        assert!(prompter.receive(&request).unwrap().is_none());
        // prompter sends the password
        let reply = prompter.send(Some(b"correct horse")).unwrap();
        let secret = client.receive(&reply).unwrap().unwrap();
        assert_eq!(secret.as_slice(), b"correct horse");
        // block sized secrets get a whole padding block
        let reply = prompter.send(Some(b"0123456789abcdef")).unwrap();
        assert_eq!(
            client.receive(&reply).unwrap().unwrap().as_slice(),
            b"0123456789abcdef"
        );
    }

    /// Talks to libgcr's own GcrSecretExchange through PyGObject (tests/gcr_sx.py),
    /// run with SHELL_AUTH_SX_PYTHON=<python with pygobject>
    /// GI_TYPELIB_PATH=<gcr-4 typelibs> cargo test -- --ignored
    #[test]
    #[ignore]
    fn interop_with_gcr() {
        use std::io::{BufRead, BufReader, Write};
        use std::process::{Command, Stdio};

        let python = std::env::var("SHELL_AUTH_SX_PYTHON").expect("SHELL_AUTH_SX_PYTHON");
        let script = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/gcr_sx.py");
        let mut child = Command::new(python)
            .arg(script)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()
            .unwrap();
        let mut stdin = child.stdin.take().unwrap();
        let mut stdout = BufReader::new(child.stdout.take().unwrap());
        let mut read = || {
            let mut line = String::new();
            stdout.read_line(&mut line).unwrap();
            line.trim_end().replace("\\n", "\n")
        };

        // we play the prompter, gcr plays gnome-keyring
        let mut prompter = Exchange::new();
        writeln!(stdin, "{}", prompter.begin().replace('\n', "\\n")).unwrap();
        let secret = prompter
            .receive(&read())
            .unwrap()
            .expect("gcr sent a secret");
        assert_eq!(secret.as_slice(), "gcr says ñ 0123456789".as_bytes());
        let reply = prompter.send(Some(b"hunter2")).unwrap();
        writeln!(stdin, "{}", reply.replace('\n', "\\n")).unwrap();
        // gcr decrypts and unpads, any key or padding mismatch fails
        assert_eq!(read(), "True");
        child.wait().unwrap();
    }

    #[test]
    fn rejects_foreign_messages() {
        let mut exchange = Exchange::new();
        assert!(exchange.receive("[other]\npublic=AA==\n").is_err());
    }
}
