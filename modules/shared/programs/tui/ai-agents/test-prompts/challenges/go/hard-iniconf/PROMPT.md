# INI-style config parser (Go 1.26)

Implement package `iniconf` (module `example.com/iniconf`) in `iniconf.go`.
The stub in `iniconf.go` shows every exported name the tests use; keep those
names and signatures exactly.

## Input format

Read the input line by line (lines are 1-based; `\r\n` and `\n` both end a line).
Leading/trailing spaces and tabs of every line are ignored.

- Blank lines and lines starting with `#` or `;` are ignored.
- `[name]` starts a section. Following keys are stored as `name.key`.
  Keys before any section have no prefix. `name` must be a valid key name.
- `key = value` sets a key. Spaces around `key` and `value` are trimmed.
  A key name is 1 or more of `a-z`, `0-9`, `_`, `-` (lowercase only).
- If the trimmed value starts with `"`, it is a quoted string that must end with
  the last character of the line. Inside it, `\"` means `"`, `\\` means `\`,
  `\n` means a newline; any other backslash escape or an unescaped `"` before
  the end is a syntax error. Quotes keep inner spaces: `k = "  a "` is `  a `.
- An unquoted value is taken as-is (may be empty, may contain `=`).

## Errors

```go
var (
	ErrSyntax       = errors.New("syntax error")    // malformed line, bad section header, bad quoting
	ErrBadKey       = errors.New("invalid key")     // key or section name has illegal characters
	ErrDuplicateKey = errors.New("duplicate key")   // full key (with section prefix) already set
	ErrNotFound     = errors.New("key not found")
)

type ParseError struct {
	Line int
	Err  error // one of ErrSyntax, ErrBadKey, ErrDuplicateKey
}
```

- `(*ParseError).Error()` returns `line <Line>: <Err>`, e.g. `line 3: duplicate key`.
- `errors.Is(pe, ErrDuplicateKey)` must be true when `pe.Err` is `ErrDuplicateKey`.
- A line `foo` with no `=` (and not a section/comment) is `ErrSyntax`.
  A line `= v` (empty key) is `ErrBadKey`. `[Bad]` is `ErrBadKey`, `[x` is `ErrSyntax`.
- A duplicate keeps the first value.

## API

```go
func Parse(r io.Reader) (*Config, error)
```
Parsing does not stop at a bad line. `Parse` always returns a non-nil `*Config`
holding every valid entry. If any lines were bad, the error is all `*ParseError`
values (one per bad line, in line order) combined with `errors.Join`; otherwise
the error is nil. A read error from `r` is returned as-is (wrapped is fine).

```go
func (c *Config) Get(key string) (string, bool)
func (c *Config) Len() int
func (c *Config) Keys() iter.Seq[string]          // all keys, sorted ascending
func (c *Config) All() iter.Seq2[string, string]  // key/value pairs, sorted by key
func (c *Config) Int(key string) (int, error)
```

- `Keys` and `All` must stop as soon as the loop body breaks.
- `Int` parses the value with `strconv.Atoi`. Missing key: return an error
  wrapping `ErrNotFound` whose message contains the key. Bad number: return an
  error that wraps the `*strconv.NumError` (so `errors.As` finds it).

## Example

```
# server
name = demo
[http]
port = 8080
greeting = "hi \"you\""
port = 9090
bad line
```
gives `name=demo`, `http.port=8080`, `http.greeting=hi "you"`, and an error
that joins `line 6: duplicate key` and `line 7: syntax error`.
