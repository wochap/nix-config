# Lua: semantic versions

Runtime: LuaJIT 2.1 (`luajit`, Lua 5.1 semantics).

Write `semver.lua`, a module (`local semver = require('semver')`) with three functions.
It must not create global variables.

## `semver.parse(s)` → `table` or `nil, errmsg`

Strict SemVer 2.0.0: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`.

- `MAJOR`, `MINOR`, `PATCH`: digits only, no leading zeros (`0` is fine, `01` is not).
- `PRERELEASE` and `BUILD`: one or more dot-separated identifiers; each identifier is non-empty
  and uses only `[0-9A-Za-z-]`. A prerelease identifier made only of digits must not have
  leading zeros. Build identifiers may.
- No leading `v`, no surrounding whitespace.
- Result: `{ major = 1, minor = 2, patch = 3, prerelease = { 'alpha', 1 }, build = { '001' } }`.
  Numeric prerelease identifiers are Lua numbers, others strings. Build identifiers are strings.
  Missing parts are empty tables.
- Invalid input (including non-strings): return `nil` and an error message string.

## `semver.compare(a, b)` → `-1`, `0` or `1`

`a` and `b` are version strings. SemVer precedence: compare major, minor, patch numerically;
a version with a prerelease is lower than the same version without one; prerelease identifiers
are compared left to right: numeric ones numerically, others in ASCII order, numeric lower than
non-numeric, and if all shared identifiers are equal the one with more identifiers is higher.
Build metadata is ignored. Raises an error if either version is invalid.

`1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0`

## `semver.satisfies(version, range)` → `boolean`

A range is one or more comparator sets joined by `||` (spaces around `||` optional); the range
matches if any set matches. A set is whitespace-separated comparators that must all match;
an empty set or `*` matches any version. Comparators (`V` is a full version as accepted by `parse`):

| comparator | meaning |
| --- | --- |
| `V` or `=V` | equal to V |
| `<V` `<=V` `>V` `>=V` | compared with `compare` |
| `~V` | `>=V` and `<MAJOR.(MINOR+1).0` |
| `^V` | `>=V` and below the next change of the left-most non-zero part: `^1.2.3` → `<2.0.0`, `^0.2.3` → `<0.3.0`, `^0.0.3` → `<0.0.4` |

Prerelease rule: a version with a prerelease matches a set only if, in addition, some comparator
written in that set has a version with a prerelease and the same `MAJOR.MINOR.PATCH`
(`1.2.3-beta.2` matches `>=1.2.3-beta.1`, but `1.2.4-beta` does not match `>=1.2.3-beta.1`, and
`2.0.0-rc.1` does not match `^1.0.0`).

- An invalid `version` returns `false`.
- An invalid range (unknown operator, bad version in a comparator, non-string) raises an error
  whose message contains `invalid range`.

Examples: `satisfies('1.4.0', '^1.2.3')` → true; `satisfies('1.3.0', '~1.2.3')` → false;
`satisfies('3.1.0', '<2.0.0 || >=3.0.0 <4.0.0')` → true.

Tests: `luajit tests/run.lua`. The code must pass `stylua --check .` (config in `stylua.toml`)
and `luacheck .` (config in `.luacheckrc`).
