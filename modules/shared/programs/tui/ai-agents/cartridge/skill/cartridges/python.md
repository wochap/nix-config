# python cartridge — target: Python 3.13

## Rules (DON'T → DO)
- DON'T `from typing import List, Dict, Optional, Union` → DO use `list[int]`, `dict[str, int]`, `X | None`, `A | B`.
- DON'T `from typing import Callable, Iterable, Sequence` → DO import them from `collections.abc`.
- DON'T `TypeVar("T")` + `Generic[T]` → DO use PEP 695 syntax: `def f[T](x: T) -> T`, `class Box[T]:`.
- DON'T `X: TypeAlias = ...` → DO `type X = ...`.
- DON'T return `"MyClass"` from methods → DO return `typing.Self`.
- DON'T override silently → DO mark overrides with `@typing.override`.
- DON'T use mutable defaults `def f(x=[])` → DO `def f(x: list[int] | None = None)` then `x = [] if x is None else x`.
- DON'T use `os.path` / `open(os.path.join(...))` → DO use `pathlib.Path` (`p / "a.txt"`, `p.read_text()`).
- DON'T use `os.system` or `shell=True` → DO `subprocess.run([...], check=True, capture_output=True, text=True)`.
- DON'T use `datetime.utcnow()` / `utcfromtimestamp()` (deprecated) → DO `datetime.now(UTC)` / `datetime.fromtimestamp(ts, UTC)`.
- DON'T create naive datetimes for real times → DO always pass `tz=` (`from datetime import UTC`).
- DON'T `loop = asyncio.get_event_loop(); loop.run_until_complete(...)` → DO `asyncio.run(main())`.
- DON'T `asyncio.gather` when one failure should cancel the rest → DO `async with asyncio.TaskGroup() as tg:`.
- DON'T `asyncio.wait_for` for blocks → DO `async with asyncio.timeout(5):`.
- DON'T call blocking I/O in async code → DO `await asyncio.to_thread(fn, *args)`.
- DON'T `== None` / `== True` → DO `is None` / plain truthiness.
- DON'T use `is` to compare strings or numbers → DO use `==`.
- DON'T `except:` or `except Exception: pass` → DO catch specific exceptions; re-raise with `raise ... from e`.
- DON'T `"%s" % x` or `.format()` → DO f-strings; debug with `f"{x=}"`.
- DON'T write `__init__` boilerplate for data → DO `@dataclass(slots=True, frozen=True)` (add `kw_only=True` for many fields).
- DON'T chain long `if/elif` on shapes → DO `match` with patterns.
- DON'T `pip install` into system Python → DO `uv venv` / `python -m venv .venv` then install.
- DON'T use `setup.py` → DO use `pyproject.toml`.
- DON'T use black+isort+flake8 → DO `ruff format` + `ruff check`.
- DON'T `open(p)` without encoding → DO `open(p, encoding="utf-8")` or `Path.read_text(encoding="utf-8")`.

## Gotchas
- Default arguments are evaluated once at def time; a list/dict default is shared across calls.
- Closures in loops bind late: `[lambda: i for i in range(3)]` all return 2. Use `lambda i=i: i`.
- `is` checks identity; small int and string caching makes `is` look right by accident.
- Modules REMOVED (import fails): `distutils` (3.12), `imp` (3.12), `asyncore`, `asynchat`, `smtpd` (3.12).
- Removed in 3.13: `cgi`, `cgitb`, `crypt`, `telnetlib`, `pipes`, `nntplib`, `audioop`, `imghdr`, `sndhdr`, `uu`, `xdrlib`, `msilib`, `chunk`, `mailcap`, `nis`, `spwd`, `sunau`, `ossaudiodev`, `lib2to3`.
- Replacements: `imp` → `importlib`; `distutils` → `setuptools`/`sysconfig`; `pipes.quote` → `shlex.quote`; `cgi.parse_header` → `email.message.Message`; `imghdr` → `filetype`/Pillow.
- `asyncio.get_event_loop()` with no running loop emits DeprecationWarning; use `asyncio.get_running_loop()` inside coroutines.
- Tasks from `asyncio.create_task` can be garbage-collected; keep a reference or use `TaskGroup`.
- `TaskGroup` raises `ExceptionGroup`; catch with `except* ValueError:`.
- `subprocess.run` without `check=True` ignores non-zero exit codes.
- Without `text=True`, `stdout` is `bytes`.
- `dataclass(frozen=True)` blocks assignment; use `dataclasses.replace(obj, x=1)` or `copy.replace(obj, x=1)` (3.13).
- `slots=True` dataclasses reject attributes not declared as fields.
- Dataclass mutable field defaults need `field(default_factory=list)`.
- `match` captures bare names: `case x:` binds, it does not compare. Use dotted names (`Color.RED`) or literals.
- `dict` keeps insertion order; `set` does not.
- `int("3.5")` raises; use `int(float(s))` or `Decimal` for money.
- `round(2.5) == 2` (banker's rounding).
- `str.strip("abc")` removes characters, not a prefix; use `removeprefix` / `removesuffix`.
- `datetime.fromisoformat` accepts `Z` suffix and most ISO 8601 since 3.11.
- `tomllib` is stdlib (read only); there is no `tomllib.dump`.
- Typing `TypeIs` (3.13) narrows both branches; `TypeGuard` only narrows the true branch.
- Free-threaded (no-GIL) build is experimental; do not assume threads run Python code in parallel.

## Correct API names
- `list.push` → `list.append`; `list.length` → `len(lst)`.
- `str.contains` → `"x" in s`; `str.startsWith` → `str.startswith`.
- `dict.has_key` → `k in d`; `dict.iteritems` → `dict.items`.
- `itertools.chunked` → `itertools.batched(it, n)` (3.12+).
- `functools.lru_cache(maxsize=None)` → `functools.cache`.
- `Path.walk` is real (3.12+); `Path.glob("**/*.py")` / `Path.rglob("*.py")`.
- `Path.from_uri` and `Path.full_match` are real (3.13).
- `pathlib.Path.write` → `write_text` / `write_bytes`.
- `os.cpu_count` counts all CPUs; `os.process_cpu_count()` (3.13) counts usable ones.
- `typing.deprecated` → `warnings.deprecated` (3.13).
- `typing.override` and `typing.Self` are real; `typing.ReadOnly` (3.13) for TypedDict fields.
- `json.loads(path)` → `json.loads(Path(p).read_text())` or `json.load(f)`.
- `asyncio.timeout_at` and `asyncio.timeout` are real (3.11+); `asyncio.Timeout` is the context class.
- `datetime.UTC` is an alias of `datetime.timezone.utc` (3.11+).

## Idioms
```python
from pathlib import Path
for p in Path("src").rglob("*.py"):
    text = p.read_text(encoding="utf-8")
```
```python
r = subprocess.run(["git", "status", "--short"], check=True, capture_output=True, text=True)
print(r.stdout)
```
```python
from dataclasses import dataclass, field
@dataclass(slots=True, frozen=True)
class Point:
    x: float
    y: float
    tags: list[str] = field(default_factory=list)
```
```python
async def main() -> None:
    async with asyncio.TaskGroup() as tg:
        t1 = tg.create_task(fetch(a))
        t2 = tg.create_task(fetch(b))
    print(t1.result(), t2.result())
asyncio.run(main())
```
```python
match cmd:
    case {"op": "add", "n": int(n)}: total += n
    case ["go", direction]: move(direction)
    case _: raise ValueError(cmd)
```
```python
from datetime import datetime, UTC
now = datetime.now(UTC)
```

## Tooling
- Project: `uv init`, `uv add requests`, `uv add --dev pytest`, `uv run python main.py`.
- Env without uv: `python -m venv .venv && . .venv/bin/activate && pip install -e .`
- Lint: `ruff check .` (`--fix` to autofix); format: `ruff format .`
- Types: `mypy .` or `pyright`.
- Test: `pytest -q`; one test: `pytest path/test_x.py::test_name`; stop on first fail: `-x`.
- Run module: `python -m pkg.mod`.
