# Integer expression calculator (C++23, GCC 15)

Implement `src/calc.cpp` for the declarations in `src/calc.hpp` (do not change
the header's declarations; you may add more files under `src/`).

```cpp
enum class ErrorKind { Syntax, DivideByZero, UnknownVariable, Overflow };
struct EvalError {
    ErrorKind kind;
    std::size_t pos;    // byte offset into the input
    std::string detail; // variable name for UnknownVariable, otherwise empty
    bool operator==(const EvalError &) const = default;
};
using Env = std::map<std::string, long long, std::less<>>;

std::expected<long long, EvalError> evaluate(std::string_view expr, const Env &env);
std::expected<long long, EvalError> execute(std::string_view line, Env &env);
std::string describe(const EvalError &err);
```

## Grammar (`evaluate`)

```
expr    := term    { ('+' | '-') term }          left-associative
term    := unary   { ('*' | '/' | '%') unary }   left-associative
unary   := '-' unary | primary
primary := number | identifier | '(' expr ')'
```

- Whitespace (`std::isspace`) may appear between any tokens.
- `number`: one or more ASCII digits, base 10 (leading zeros allowed). There is no unary `+`.
- `identifier`: `[A-Za-z_][A-Za-z0-9_]*`, looked up in `env` (case-sensitive).
- All values are `long long`. `/` truncates toward zero; `%` follows C++ (sign of the left operand).
- The whole input must be one `expr`; anything left over is a syntax error.

## Errors

Evaluate while parsing, left to right. The first error found stops everything,
even if the rest of the input is malformed (`"1/0 +"` → DivideByZero at 1).

| kind | when | `pos` |
|---|---|---|
| `Syntax` | unexpected character or unexpected end | index of that character (after skipping whitespace), or `expr.size()` at end of input |
| `UnknownVariable` | identifier not in `env` | index of the identifier's first char; `detail` = the name |
| `DivideByZero` | right side of `/` or `%` is 0 | index of the operator |
| `Overflow` | result does not fit in `long long` (incl. `MIN / -1`, `MIN % -1`, `-MIN`) | index of the operator (for unary minus: the `-`) |
| `Overflow` | number literal too large for `long long` | index of the literal's first digit |

There must be no undefined behaviour: tests run with `-fsanitize=address,undefined`.

Examples: `evaluate("1 + 2 * 3", {})` → `7`; `"1 +"` → Syntax at 3; `"2x"` → Syntax at 1;
`"x + y"` with `x` defined → UnknownVariable at 4, detail `"y"`;
`"9223372036854775807 + 1"` → Overflow at 20; `"9223372036854775808"` → Overflow at 0.

## `execute`

If `line`, after leading whitespace, starts with an identifier followed by
optional whitespace and `=`, it is an assignment: evaluate the text after the `=`
(positions stay relative to the whole `line`), store the result in `env` under
that name (insert or overwrite) and return it. On error, `env` is unchanged.
Otherwise `line` is evaluated like `evaluate(line, env)`.

Examples: `"a = 2 + 3"` → 5 and stores `a`; `"d ="` → Syntax at 3;
`"e == 1"` → Syntax at 3; `"= 4"` → Syntax at 0.

## `describe`

| kind | text |
|---|---|
| `Syntax` | `syntax error at <pos>` |
| `DivideByZero` | `division by zero at <pos>` |
| `UnknownVariable` | `unknown variable '<detail>' at <pos>` |
| `Overflow` | `overflow at <pos>` |

`tests/test.cpp` is compiled with
`g++ -std=c++23 -Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined`.
Code must also pass `clang-format` and `clang-tidy` as run by `check.sh`.
Run `bash check.sh`.
