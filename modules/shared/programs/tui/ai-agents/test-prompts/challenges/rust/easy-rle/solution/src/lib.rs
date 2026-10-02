use std::fmt::Write;

/// Run-length encode `s`.
pub fn encode(s: &str) -> String {
    let mut out = String::new();
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        let mut n = 1;
        while chars.next_if_eq(&c).is_some() {
            n += 1;
        }
        if n > 1 {
            write!(out, "{n}").expect("writing to String cannot fail");
        }
        out.push(c);
    }
    out
}
