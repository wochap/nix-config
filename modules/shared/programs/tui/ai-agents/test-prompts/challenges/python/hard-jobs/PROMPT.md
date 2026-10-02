# Async job runner

Implement `jobs.py` (Python 3.13, standard library only).

## Data types
Both are frozen dataclasses with `slots=True` and keyword-only fields:

```python
class Job:
    name: str
    timeout: float            # seconds allowed per attempt
    retries: int              # extra attempts after a failed/timed-out one
    tags: tuple[str, ...] = ()

class Result:
    name: str
    status: Literal["ok", "failed", "timeout"]
    attempts: int             # attempts made, >= 1
    output: str | None        # value returned by work when status is "ok", else None
    error: str | None         # "failed": f"{type(exc).__name__}: {exc}" of the last
                              # exception; otherwise None
    finished_at: datetime     # timezone-aware, UTC, when the job finished
```

## `load_jobs(path: Path) -> list[Job]`
Reads a TOML file:

```toml
[defaults]        # optional table
timeout = 2.0     # optional, built-in default 1.0
retries = 1       # optional, built-in default 0

[[job]]
name = "build"
timeout = 0.5     # optional, falls back to [defaults]
retries = 0       # optional, falls back to [defaults]
tags = ["ci"]     # optional list of strings, default empty
```

Returns jobs in file order (`[]` when there is no `[[job]]`). `timeout` may be
written as an integer or a float and is stored as `float`. Raise `ValueError`
for: invalid TOML; a top-level key other than `defaults` and `job`; unknown
keys inside `[defaults]` or a job; a missing or empty `name`; a duplicate
`name`; `timeout` that is not a number greater than 0; `retries` that is not an
integer >= 0; `tags` that is not a list of strings. Booleans are not numbers
here (`retries = true` is invalid). When the error is about a named job, the
message contains the job's name.

## `async run_jobs(jobs, work, limit) -> list[Result]`
```python
async def run_jobs(
    jobs: Sequence[Job], work: Callable[[Job], Awaitable[str]], limit: int
) -> list[Result]: ...
```
- Runs `await work(job)` for every job, with at most `limit` jobs running at
  the same time (a job keeps its slot across its retries). `limit < 1` raises
  `ValueError`.
- Each attempt may take at most `job.timeout` seconds; when it runs out, the
  attempt is cancelled and counts as a timeout.
- An attempt that raises an `Exception` counts as failed. Failed and timed-out
  attempts are retried until `1 + job.retries` attempts were made; the status
  comes from the last attempt.
- A failing job never stops the other jobs. Results are in the order of `jobs`.

## `summarize(results: Iterable[Result]) -> dict[str, int]`
Counts results by status; always has the keys `"ok"`, `"failed"`, `"timeout"`.

The code must pass `ruff format --check`, `ruff check` and `mypy` in strict
mode (config in `pyproject.toml`). Tests: `pytest tests` (they call
`asyncio.run`).
