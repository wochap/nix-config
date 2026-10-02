use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Account {
    pub name: String,
    pub balance: u64,
    pub frozen: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LedgerError {
    UnknownAccount(String),
    Duplicate(String),
    Insufficient {
        name: String,
        needed: u64,
        available: u64,
    },
    Frozen(String),
    Overflow,
    SameAccount,
    Parse(String),
}

impl fmt::Display for LedgerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "TODO")
    }
}

impl std::error::Error for LedgerError {}

#[derive(Debug, Default)]
pub struct Ledger {
    accounts: Vec<Account>,
}

impl Ledger {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn open(&mut self, _name: &str, _initial: u64) -> Result<(), LedgerError> {
        todo!()
    }

    pub fn balance(&self, _name: &str) -> Option<u64> {
        todo!()
    }

    pub fn accounts(&self) -> &[Account] {
        &self.accounts
    }

    pub fn deposit(&mut self, _name: &str, _amount: u64) -> Result<u64, LedgerError> {
        todo!()
    }

    pub fn withdraw(&mut self, _name: &str, _amount: u64) -> Result<u64, LedgerError> {
        todo!()
    }

    pub fn transfer(&mut self, _from: &str, _to: &str, _amount: u64) -> Result<(), LedgerError> {
        todo!()
    }

    pub fn freeze(&mut self, _name: &str) -> Result<(), LedgerError> {
        todo!()
    }

    pub fn close_empty(&mut self) -> Vec<Account> {
        todo!()
    }

    pub fn execute(&mut self, _line: &str) -> Result<String, LedgerError> {
        todo!()
    }
}
