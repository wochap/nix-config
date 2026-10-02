# Run-length encoding (Rust, edition 2024)

Library crate `rle`. Implement in `src/lib.rs`:

```rust
pub fn encode(s: &str) -> String
```

- Work on Unicode `char`s, not bytes.
- Each run of the same char becomes `<count><char>`; a run of length 1 is just `<char>`.
- Empty input gives an empty string.
- Input never contains ASCII digits.

Examples:

```
encode("aaabcc")   == "3ab2c"
encode("abc")      == "abc"
encode("ééé日日x") == "3é2日x"
encode("")         == ""
encode("aaaaaaaaaaaa") == "12a"
```

Tests are integration tests in `tests/`. Run `bash check.sh`.
