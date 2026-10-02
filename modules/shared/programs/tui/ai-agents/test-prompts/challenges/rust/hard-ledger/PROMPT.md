# Account ledger (Rust 1.95, edition 2024)

Library crate `ledger`, std only (no external crates). Implement in `src/lib.rs`.
The stub shows every public item the tests use; keep names and signatures exactly.

## Types

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Account { pub name: String, pub balance: u64, pub frozen: bool }

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LedgerError {
    UnknownAccount(String),
    Duplicate(String),
    Insufficient { name: String, needed: u64, available: u64 },
    Frozen(String),
    Overflow,
    SameAccount,
    Parse(String),
}

#[derive(Debug, Default)]
pub struct Ledger { /* private */ }
```

`LedgerError` implements `std::fmt::Display` and `std::error::Error`. Display text:

| variant | text |
|---|---|
| `UnknownAccount(n)` | `unknown account: <n>` |
| `Duplicate(n)` | `account exists: <n>` |
| `Insufficient{..}` | `insufficient funds in <name>: need <needed>, have <available>` |
| `Frozen(n)` | `account frozen: <n>` |
| `Overflow` | `balance overflow` |
| `SameAccount` | `cannot transfer to same account` |
| `Parse(s)` | `parse error: <s>` |

## Ledger methods

```rust
impl Ledger {
    pub fn new() -> Self;
    pub fn open(&mut self, name: &str, initial: u64) -> Result<(), LedgerError>;
    pub fn balance(&self, name: &str) -> Option<u64>;
    pub fn accounts(&self) -> &[Account];                    // in opening order
    pub fn deposit(&mut self, name: &str, amount: u64) -> Result<u64, LedgerError>;  // returns new balance
    pub fn withdraw(&mut self, name: &str, amount: u64) -> Result<u64, LedgerError>; // returns new balance
    pub fn transfer(&mut self, from: &str, to: &str, amount: u64) -> Result<(), LedgerError>;
    pub fn freeze(&mut self, name: &str) -> Result<(), LedgerError>;
    pub fn close_empty(&mut self) -> Vec<Account>;
    pub fn execute(&mut self, line: &str) -> Result<String, LedgerError>;
}
```

Rules (check errors in exactly this order; a failed call changes nothing):

- `open`: name already exists → `Duplicate`.
- `deposit`/`withdraw`: unknown → `UnknownAccount`; frozen → `Frozen`;
  withdraw more than balance → `Insufficient { name, needed: amount, available: balance }`;
  deposit past `u64::MAX` → `Overflow`.
- `transfer`: unknown `from`, then unknown `to` → `UnknownAccount`;
  `from == to` → `SameAccount`; `from` frozen, then `to` frozen → `Frozen`;
  then `Insufficient` (for `from`), then `Overflow` (for `to`).
- `freeze`: unknown → `UnknownAccount`. Freezing twice is fine.
- Amount 0 is allowed everywhere.
- `close_empty`: removes every account with balance 0 that is not frozen and
  returns them in opening order; remaining accounts keep their order.

## `execute`

Splits `line` on whitespace (any amount). Commands:

| line | result |
|---|---|
| `open <name> <amount>` | `ok` |
| `deposit <name> <amount>` | `<name>: <new balance>` |
| `withdraw <name> <amount>` | `<name>: <new balance>` |
| `transfer <from> <to> <amount>` | `ok` |
| `balance <name>` | `<name>: <balance>` (unknown → `UnknownAccount`) |
| `freeze <name>` | `ok` |
| `close` | names closed by `close_empty`, joined with `,` (empty string if none) |

Unknown command, wrong number of arguments, or an amount that is not a valid
`u64` (e.g. `-5`, `1.5`, `abc`, too large) → `Parse(<line trimmed>)`.

Example: `open alice 100`, `open bob 0`, `transfer alice bob 30`, `balance bob` → `bob: 30`.
