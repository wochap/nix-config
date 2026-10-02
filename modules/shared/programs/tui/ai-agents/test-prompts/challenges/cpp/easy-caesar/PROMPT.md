# Caesar cipher (C++23, GCC 15)

Implement in `src/caesar.cpp` the function declared in `src/caesar.hpp`:

```cpp
std::string caesar(std::string_view text, int shift);
```

- Shift each ASCII letter `a-z` / `A-Z` by `shift` positions in the alphabet,
  wrapping around and keeping its case.
- `shift` can be any `int`, including negative values, values beyond ±26,
  `INT_MAX` and `INT_MIN`.
- Every other byte (digits, punctuation, spaces, non-ASCII UTF-8 bytes, `'\0'`)
  is copied unchanged. The result has the same length as `text`.

Examples:

```
caesar("abc", 1)            == "bcd"
caesar("Hello, World!", 13) == "Uryyb, Jbeyq!"
caesar("abc", -27)          == "zab"
caesar("café", 1)           == "dbgé"
```

`tests/test.cpp` is compiled with
`g++ -std=c++23 -Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined`.
Code must also pass `clang-format` and `clang-tidy` as run by `check.sh`.
Run `bash check.sh`.
