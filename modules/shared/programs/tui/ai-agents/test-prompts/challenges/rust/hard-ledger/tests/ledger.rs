use ledger::{Account, Ledger, LedgerError};

fn setup() -> Ledger {
    let mut l = Ledger::new();
    l.open("alice", 100).unwrap();
    l.open("bob", 0).unwrap();
    l
}

fn unknown(n: &str) -> LedgerError {
    LedgerError::UnknownAccount(n.to_string())
}

#[test]
fn error_trait_and_display() {
    fn assert_error<E: std::error::Error + Send + Sync + 'static>(_: &E) {}
    let e = LedgerError::Overflow;
    assert_error(&e);
    let boxed: Box<dyn std::error::Error> = Box::new(LedgerError::SameAccount);
    assert_eq!(boxed.to_string(), "cannot transfer to same account");
    assert_eq!(unknown("x").to_string(), "unknown account: x");
    assert_eq!(
        LedgerError::Duplicate("x".into()).to_string(),
        "account exists: x"
    );
    assert_eq!(
        LedgerError::Insufficient {
            name: "a".into(),
            needed: 5,
            available: 2
        }
        .to_string(),
        "insufficient funds in a: need 5, have 2"
    );
    assert_eq!(
        LedgerError::Frozen("z".into()).to_string(),
        "account frozen: z"
    );
    assert_eq!(LedgerError::Overflow.to_string(), "balance overflow");
    assert_eq!(
        LedgerError::Parse("foo 1".into()).to_string(),
        "parse error: foo 1"
    );
}

#[test]
fn default_is_empty() {
    let l = Ledger::default();
    assert!(l.accounts().is_empty());
    assert_eq!(l.balance("alice"), None);
}

#[test]
fn open_and_duplicate() {
    let mut l = setup();
    assert_eq!(
        l.open("alice", 5),
        Err(LedgerError::Duplicate("alice".into()))
    );
    assert_eq!(l.balance("alice"), Some(100));
    assert_eq!(l.accounts().len(), 2);
}

#[test]
fn deposit_withdraw() {
    let mut l = setup();
    assert_eq!(l.deposit("bob", 7), Ok(7));
    assert_eq!(l.withdraw("alice", 40), Ok(60));
    assert_eq!(l.withdraw("alice", 0), Ok(60));
    assert_eq!(
        l.withdraw("bob", 8),
        Err(LedgerError::Insufficient {
            name: "bob".into(),
            needed: 8,
            available: 7
        })
    );
    assert_eq!(l.deposit("carol", 1), Err(unknown("carol")));
    assert_eq!(l.withdraw("carol", 1), Err(unknown("carol")));
    l.deposit("bob", u64::MAX - 7).unwrap();
    assert_eq!(l.deposit("bob", 1), Err(LedgerError::Overflow));
    assert_eq!(l.balance("bob"), Some(u64::MAX));
}

#[test]
fn frozen_accounts() {
    let mut l = setup();
    l.freeze("bob").unwrap();
    l.freeze("bob").unwrap();
    assert_eq!(l.freeze("nobody"), Err(unknown("nobody")));
    assert_eq!(l.deposit("bob", 1), Err(LedgerError::Frozen("bob".into())));
    assert_eq!(l.withdraw("bob", 0), Err(LedgerError::Frozen("bob".into())));
    assert_eq!(
        l.transfer("alice", "bob", 1),
        Err(LedgerError::Frozen("bob".into()))
    );
    l.freeze("alice").unwrap();
    assert_eq!(
        l.transfer("alice", "bob", 1),
        Err(LedgerError::Frozen("alice".into()))
    );
    assert!(l.accounts().iter().all(|a| a.frozen));
}

#[test]
fn transfer_ok_and_errors() {
    let mut l = setup();
    l.transfer("alice", "bob", 30).unwrap();
    assert_eq!(l.balance("alice"), Some(70));
    assert_eq!(l.balance("bob"), Some(30));
    l.transfer("bob", "alice", 0).unwrap();
    assert_eq!(l.transfer("x", "y", 1), Err(unknown("x")));
    assert_eq!(l.transfer("alice", "y", 1), Err(unknown("y")));
    assert_eq!(l.transfer("x", "alice", 1), Err(unknown("x")));
    assert_eq!(
        l.transfer("alice", "alice", 1),
        Err(LedgerError::SameAccount)
    );
    assert_eq!(
        l.transfer("alice", "bob", 71),
        Err(LedgerError::Insufficient {
            name: "alice".into(),
            needed: 71,
            available: 70
        })
    );
    // Same-account check comes before the frozen check.
    l.freeze("bob").unwrap();
    assert_eq!(l.transfer("bob", "bob", 1), Err(LedgerError::SameAccount));
}

#[test]
fn transfer_overflow_is_atomic() {
    let mut l = Ledger::new();
    l.open("rich", u64::MAX).unwrap();
    l.open("a", 10).unwrap();
    assert_eq!(l.transfer("a", "rich", 1), Err(LedgerError::Overflow));
    assert_eq!(l.balance("a"), Some(10));
    assert_eq!(l.balance("rich"), Some(u64::MAX));
    // Insufficient is reported before overflow.
    assert_eq!(
        l.transfer("a", "rich", 11),
        Err(LedgerError::Insufficient {
            name: "a".into(),
            needed: 11,
            available: 10
        })
    );
}

#[test]
fn close_empty_keeps_order() {
    let mut l = Ledger::new();
    for (n, b) in [("a", 0), ("b", 5), ("c", 0), ("d", 0), ("e", 1)] {
        l.open(n, b).unwrap();
    }
    l.freeze("d").unwrap();
    let closed = l.close_empty();
    assert_eq!(
        closed,
        vec![
            Account {
                name: "a".into(),
                balance: 0,
                frozen: false
            },
            Account {
                name: "c".into(),
                balance: 0,
                frozen: false
            },
        ]
    );
    let names: Vec<&str> = l.accounts().iter().map(|a| a.name.as_str()).collect();
    assert_eq!(names, ["b", "d", "e"]);
    assert!(l.close_empty().is_empty());
    // A closed name can be opened again.
    l.open("a", 3).unwrap();
    assert_eq!(l.accounts().last().map(|a| a.name.as_str()), Some("a"));
}

#[test]
fn execute_commands() {
    let mut l = Ledger::new();
    let mut run = |s: &str| l.execute(s);
    assert_eq!(run("open alice 100").as_deref(), Ok("ok"));
    assert_eq!(run("  open   bob\t0 ").as_deref(), Ok("ok"));
    assert_eq!(run("transfer alice bob 30").as_deref(), Ok("ok"));
    assert_eq!(run("balance bob").as_deref(), Ok("bob: 30"));
    assert_eq!(run("deposit bob 5").as_deref(), Ok("bob: 35"));
    assert_eq!(run("withdraw alice 70").as_deref(), Ok("alice: 0"));
    assert_eq!(run("open carol 0").as_deref(), Ok("ok"));
    assert_eq!(run("freeze bob").as_deref(), Ok("ok"));
    assert_eq!(run("close").as_deref(), Ok("alice,carol"));
    assert_eq!(run("close").as_deref(), Ok(""));
    assert_eq!(run("balance alice"), Err(unknown("alice")));
    assert_eq!(run("deposit bob 1"), Err(LedgerError::Frozen("bob".into())));
}

#[test]
fn execute_parse_errors() {
    let mut l = setup();
    for line in [
        "deposit alice -5",
        "deposit alice 1.5",
        "deposit alice abc",
        "deposit alice 18446744073709551616",
        "deposit alice",
        "deposit alice 1 2",
        "balance",
        "close now",
        "fly alice",
        "",
        "  OPEN dave 1  ",
    ] {
        assert_eq!(
            l.execute(line),
            Err(LedgerError::Parse(line.trim().to_string())),
            "line {line:?}"
        );
    }
    assert_eq!(l.balance("alice"), Some(100));
    assert_eq!(
        l.execute("deposit alice 18446744073709551615"),
        Err(LedgerError::Overflow)
    );
}
