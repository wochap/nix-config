# rust cartridge — target: Rust 1.95, edition 2024

## Rules (DON'T → DO)
- DON'T `fn f(s: String)` / `fn f(s: &String)` for read-only text → DO `fn f(s: &str)`
- DON'T `fn f(v: &Vec<T>)` → DO `fn f(v: &[T])`
- DON'T `.clone()` to silence the borrow checker → DO borrow (`&x`), restructure scopes, or move
- DON'T `.unwrap()` / `.expect()` in library code → DO return `Result` and use `?`
- DON'T `match r { Ok(v) => v, Err(e) => return Err(e.into()) }` → DO `r?`
- DON'T `Box<dyn Error>` everywhere in libs → DO a `thiserror` enum; use `anyhow::Result` in binaries
- DON'T `lazy_static!` / `once_cell::Lazy` → DO `std::sync::LazyLock` (static) / `std::sync::OnceLock`
- DON'T `for i in 0..v.len() { v[i] }` → DO `for x in &v` or `v.iter().enumerate()`
- DON'T `if x.is_some() { x.unwrap() }` → DO `if let Some(v) = x`
- DON'T nest `if let` → DO let chains: `if let Some(a) = x && let Some(b) = y && a < b` (edition 2024)
- DON'T `let v = match o { Some(v) => v, None => return };` → DO `let Some(v) = o else { return };`
- DON'T `extern "C" { ... }` → DO `unsafe extern "C" { ... }` (required in 2024)
- DON'T `#[no_mangle]` / `#[export_name]` → DO `#[unsafe(no_mangle)]` (required in 2024)
- DON'T call `std::env::set_var` / `remove_var` bare → DO wrap in `unsafe { }` (unsafe in 2024)
- DON'T name anything `gen` → DO `r#gen` (keyword reserved in 2024; e.g. `rng.r#gen()` or `rng.random()` in rand 0.9)
- DON'T `Rc<RefCell<T>>` across threads → DO `Arc<Mutex<T>>` / `Arc<RwLock<T>>`
- DON'T hold a `std::sync::Mutex` guard across `.await` → DO drop it first or use `tokio::sync::Mutex`
- DON'T write `async fn main` without a runtime → DO `#[tokio::main] async fn main()`
- DON'T `x as u8` for narrowing that may overflow → DO `u8::try_from(x)?`
- DON'T `&s[0..n]` on non-ASCII text → DO `s.chars()` / `s.char_indices()` (byte slicing panics mid-char)
- DON'T `.collect::<Vec<_>>().len()` → DO `.count()`
- DON'T `std::mem::uninitialized` → DO `MaybeUninit`
- DON'T `try!(x)` → DO `x?`
- DON'T `impl Trait` arg + explicit turbofish on it → DO a named generic `fn f<T: Trait>(x: T)`

## Gotchas
- One `&mut` OR many `&` at a time; a borrow lives until its last use.
- Edition 2024: `-> impl Trait` captures all in-scope lifetimes; use `+ use<'a, T>` to narrow.
- Edition 2024: `if let` temporaries drop before the `else` block; tail-expression temporaries drop before locals.
- Edition 2024: unsafe ops inside `unsafe fn` warn; wrap them in `unsafe {}` blocks.
- Edition 2024: `static mut` references are denied; use atomics, `Mutex`, or `&raw mut`.
- Edition 2024: `IntoIterator for Box<[T]>` yields values, not refs.
- `String` is owned, `&str` is borrowed; `"lit"` is `&'static str`; convert with `.to_string()` / `String::from`.
- `?` converts errors via `From`; implement `From<E>` or use `#[from]` in thiserror.
- `?` on `Option` only works in functions returning `Option`; use `.ok_or(err)?` to switch.
- Lifetime elision: one input ref → output gets that lifetime; `&self` methods → output gets self's.
- Integer overflow panics in debug, wraps in release; use `checked_*`, `wrapping_*`, `saturating_*`.
- `HashMap` iteration order is random; use `BTreeMap` for sorted keys.
- Iterators are lazy; `.map()` without `.collect()`/`for` does nothing.
- `iter()` borrows, `iter_mut()` borrows mutably, `into_iter()` consumes.
- Closures capturing by ref cannot outlive the data; use `move ||` for threads.
- `std::thread::scope` lets threads borrow locals without `Arc`.
- Async fns do nothing until awaited or spawned.
- Async closures `async || {}` are stable (1.85); `AsyncFn` traits exist.
- `#[derive(Default)]` on enums needs `#[default]` on one variant.
- Trait objects need `dyn`: `Box<dyn Trait>`, `&dyn Trait`.

## Correct API names
- `lazy_static::lazy_static!` → `std::sync::LazyLock::new(|| ...)`
- `once_cell::sync::OnceCell` → `std::sync::OnceLock`
- `Vec::drain_filter` → `Vec::extract_if(.., pred)`
- `slice.get_many_mut` → `slice.get_disjoint_mut([i, j])` (returns `Result`)
- `Option::is_some_and(f)` / `Option::is_none_or(f)` exist; no `Option::contains`
- `iter.is_sorted()` / `slice.is_sorted_by_key(f)`
- `str::split_once(':')` returns `Option<(&str, &str)>`
- `HashMap::from([(k, v)])` to build from array
- `std::io::read_to_string(reader)` / `std::fs::read_to_string(path)`
- `std::iter::repeat_n(x, n)` instead of `repeat(x).take(n)`
- `Result::inspect_err(f)` for logging without consuming
- `i32::midpoint(a, b)` / `u32::div_ceil(n)` / `u32::isqrt()` exist
- `std::path::Path::new(s).extension()` returns `Option<&OsStr>`

## Idioms
```rust
fn parse_kv(s: &str) -> Option<(&str, u32)> {
    let (k, v) = s.split_once('=')?;
    Some((k, v.trim().parse().ok()?))
}
```
```rust
#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("bad input: {0}")]
    Bad(String),
}
```
```rust
static CFG: LazyLock<HashMap<&'static str, u32>> =
    LazyLock::new(|| HashMap::from([("a", 1)]));
```
```rust
let Some(user) = find(id) else { return Err(AppError::Bad(id.into())) };
```
```rust
let total: u32 = items.iter().filter(|i| i.active).map(|i| i.qty).sum();
let names: Vec<&str> = items.iter().map(|i| i.name.as_str()).collect();
```
```rust
let counter = Arc::new(Mutex::new(0));
let c = Arc::clone(&counter);
std::thread::spawn(move || *c.lock().unwrap() += 1).join().unwrap();
```

## Tooling
- `cargo new app` (bin) / `cargo new --lib lib`; new projects default to `edition = "2024"`
- `cargo add serde --features derive` / `cargo add tokio --features full`
- `cargo build` / `cargo run -- args` / `cargo build --release`
- `cargo test` / `cargo test name -- --nocapture`
- `cargo check` for fast type-check
- `cargo clippy --all-targets -- -D warnings`
- `cargo fmt` / `cargo fmt --check`
- `cargo fix --edition` to migrate older editions
- `cargo doc --open`; `cargo tree` for dependency graph
