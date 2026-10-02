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
        match self {
            Self::UnknownAccount(n) => write!(f, "unknown account: {n}"),
            Self::Duplicate(n) => write!(f, "account exists: {n}"),
            Self::Insufficient {
                name,
                needed,
                available,
            } => write!(
                f,
                "insufficient funds in {name}: need {needed}, have {available}"
            ),
            Self::Frozen(n) => write!(f, "account frozen: {n}"),
            Self::Overflow => write!(f, "balance overflow"),
            Self::SameAccount => write!(f, "cannot transfer to same account"),
            Self::Parse(s) => write!(f, "parse error: {s}"),
        }
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

    fn index(&self, name: &str) -> Result<usize, LedgerError> {
        self.accounts
            .iter()
            .position(|a| a.name == name)
            .ok_or_else(|| LedgerError::UnknownAccount(name.to_string()))
    }

    fn active_mut(&mut self, name: &str) -> Result<&mut Account, LedgerError> {
        let i = self.index(name)?;
        let acc = &mut self.accounts[i];
        if acc.frozen {
            return Err(LedgerError::Frozen(name.to_string()));
        }
        Ok(acc)
    }

    pub fn open(&mut self, name: &str, initial: u64) -> Result<(), LedgerError> {
        if self.balance(name).is_some() {
            return Err(LedgerError::Duplicate(name.to_string()));
        }
        self.accounts.push(Account {
            name: name.to_string(),
            balance: initial,
            frozen: false,
        });
        Ok(())
    }

    pub fn balance(&self, name: &str) -> Option<u64> {
        self.accounts
            .iter()
            .find(|a| a.name == name)
            .map(|a| a.balance)
    }

    pub fn accounts(&self) -> &[Account] {
        &self.accounts
    }

    pub fn deposit(&mut self, name: &str, amount: u64) -> Result<u64, LedgerError> {
        let acc = self.active_mut(name)?;
        acc.balance = acc
            .balance
            .checked_add(amount)
            .ok_or(LedgerError::Overflow)?;
        Ok(acc.balance)
    }

    pub fn withdraw(&mut self, name: &str, amount: u64) -> Result<u64, LedgerError> {
        let acc = self.active_mut(name)?;
        let Some(left) = acc.balance.checked_sub(amount) else {
            return Err(LedgerError::Insufficient {
                name: name.to_string(),
                needed: amount,
                available: acc.balance,
            });
        };
        acc.balance = left;
        Ok(left)
    }

    pub fn transfer(&mut self, from: &str, to: &str, amount: u64) -> Result<(), LedgerError> {
        let i = self.index(from)?;
        let j = self.index(to)?;
        let Ok([a, b]) = self.accounts.get_disjoint_mut([i, j]) else {
            return Err(LedgerError::SameAccount);
        };
        for acc in [&*a, &*b] {
            if acc.frozen {
                return Err(LedgerError::Frozen(acc.name.clone()));
            }
        }
        let Some(left) = a.balance.checked_sub(amount) else {
            return Err(LedgerError::Insufficient {
                name: a.name.clone(),
                needed: amount,
                available: a.balance,
            });
        };
        b.balance = b.balance.checked_add(amount).ok_or(LedgerError::Overflow)?;
        a.balance = left;
        Ok(())
    }

    pub fn freeze(&mut self, name: &str) -> Result<(), LedgerError> {
        let i = self.index(name)?;
        self.accounts[i].frozen = true;
        Ok(())
    }

    pub fn close_empty(&mut self) -> Vec<Account> {
        self.accounts
            .extract_if(.., |a| a.balance == 0 && !a.frozen)
            .collect()
    }

    pub fn execute(&mut self, line: &str) -> Result<String, LedgerError> {
        let parse_err = || LedgerError::Parse(line.trim().to_string());
        let amount = |s: &str| s.parse::<u64>().map_err(|_| parse_err());
        let words: Vec<&str> = line.split_whitespace().collect();
        match words.as_slice() {
            ["open", name, n] => {
                self.open(name, amount(n)?)?;
                Ok("ok".into())
            }
            ["deposit", name, n] => {
                let b = self.deposit(name, amount(n)?)?;
                Ok(format!("{name}: {b}"))
            }
            ["withdraw", name, n] => {
                let b = self.withdraw(name, amount(n)?)?;
                Ok(format!("{name}: {b}"))
            }
            ["transfer", from, to, n] => {
                self.transfer(from, to, amount(n)?)?;
                Ok("ok".into())
            }
            ["balance", name] => {
                let b = self.index(name).map(|i| self.accounts[i].balance)?;
                Ok(format!("{name}: {b}"))
            }
            ["freeze", name] => {
                self.freeze(name)?;
                Ok("ok".into())
            }
            ["close"] => Ok(self
                .close_empty()
                .into_iter()
                .map(|a| a.name)
                .collect::<Vec<_>>()
                .join(",")),
            _ => Err(parse_err()),
        }
    }
}
