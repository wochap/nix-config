# Run-length encoding

Implement `src/rle.js` (an ES module) with two named exports:

```js
export function encode(text) // string -> string
export function decode(text) // string -> string
```

`encode` replaces each run of identical characters with the run length
followed by the character. Every run gets a count, even a run of 1.
A "character" is a Unicode code point, so emoji and other astral characters
count as one character.

```
encode("aaabcc")  -> "3a1b2c"
encode("")        -> ""
encode("😀😀x")   -> "2😀1x"
encode("aaaaaaaaaaaa") -> "12a"
```

`decode` reverses `encode`: `decode(encode(s)) === s` for any string `s` that
contains no ASCII digits. It throws a `SyntaxError` when the input is not a
valid encoding: a character without a count before it, a count of `0`
(or with a leading zero), or a count at the end with no character.

```
decode("3a1b2c") -> "aaabcc"
decode("2😀1x")  -> "😀😀x"
decode("a")      -> throws SyntaxError
decode("3")      -> throws SyntaxError
decode("0a")     -> throws SyntaxError
```

Files: `src/rle.js`. Tests live in `tests/` and run with `node --test`.
