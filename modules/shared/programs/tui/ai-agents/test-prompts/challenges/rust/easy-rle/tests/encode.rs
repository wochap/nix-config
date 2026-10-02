use rle::encode;

#[test]
fn basic() {
    assert_eq!(encode("aaabcc"), "3ab2c");
    assert_eq!(encode("abc"), "abc");
}

#[test]
fn empty() {
    assert_eq!(encode(""), "");
}

#[test]
fn single() {
    assert_eq!(encode("z"), "z");
}

#[test]
fn unicode() {
    assert_eq!(encode("ééé日日x"), "3é2日x");
    assert_eq!(encode("🦀🦀"), "2🦀");
}

#[test]
fn long_runs() {
    assert_eq!(encode(&"a".repeat(12)), "12a");
    assert_eq!(
        encode(&format!("{}b{}", "a".repeat(100), "a".repeat(3))),
        "100ab3a"
    );
}

#[test]
fn whitespace() {
    assert_eq!(encode("  x  "), "2 x2 ");
}
