# Top words (Go)

Implement `TopWords` in `wordfreq.go` (package `wordfreq`, module `example.com/wordfreq`).

```go
func TopWords(text string, n int) []string
```

- A word is a maximal run of Unicode letters or digits (`unicode.IsLetter` / `unicode.IsDigit`).
  Everything else separates words.
- Words are case-insensitive: compare and return them in lower case.
- Return the `n` most frequent words, most frequent first. Ties are ordered
  alphabetically (ascending, by byte order of the lower-cased word).
- If there are fewer than `n` distinct words, return all of them.
- If `n <= 0` or there are no words, return an empty, non-nil slice (`[]string{}`).

Examples:

```
TopWords("the cat and the hat", 2)       -> ["the", "and"]
TopWords("B a b A c", 3)                 -> ["a", "b", "c"]
TopWords("Ünïcode, ünïcode! x2 x2 x2", 5) -> ["x2", "ünïcode"]
```

Tests live in `tests/` (package `tests`). Run `bash check.sh`.
