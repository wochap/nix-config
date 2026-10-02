import asyncio
import tomllib
from collections.abc import Awaitable, Callable, Iterable, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Literal

type Status = Literal["ok", "failed", "timeout"]

TOP_KEYS = {"defaults", "job"}
DEFAULT_KEYS = {"timeout", "retries"}
JOB_KEYS = {"name", "timeout", "retries", "tags"}


@dataclass(frozen=True, slots=True, kw_only=True)
class Job:
    name: str
    timeout: float
    retries: int
    tags: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True, kw_only=True)
class Result:
    name: str
    status: Status
    attempts: int
    output: str | None
    error: str | None
    finished_at: datetime


def _table(value: object, where: str, allowed: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError(f"{where}: expected a table")
    unknown = set(value) - allowed
    if unknown:
        raise ValueError(f"{where}: unknown keys {sorted(unknown)}")
    return value


def _timeout(value: object, where: str) -> float:
    if isinstance(value, bool) or not isinstance(value, int | float) or value <= 0:
        raise ValueError(f"{where}: timeout must be a number > 0")
    return float(value)


def _retries(value: object, where: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{where}: retries must be an integer >= 0")
    return value


def _tags(value: object, where: str) -> tuple[str, ...]:
    if not isinstance(value, list) or not all(isinstance(t, str) for t in value):
        raise ValueError(f"{where}: tags must be a list of strings")
    return tuple(value)


def load_jobs(path: Path) -> list[Job]:
    with path.open("rb") as f:
        data = _table(tomllib.load(f), "file", TOP_KEYS)
    defaults = _table(data.get("defaults", {}), "defaults", DEFAULT_KEYS)
    timeout = _timeout(defaults.get("timeout", 1.0), "defaults")
    retries = _retries(defaults.get("retries", 0), "defaults")
    raw_jobs = data.get("job", [])
    if not isinstance(raw_jobs, list):
        raise ValueError("job must be an array of tables")
    jobs: list[Job] = []
    seen: set[str] = set()
    for index, raw in enumerate(raw_jobs, start=1):
        table = _table(raw, f"job #{index}", JOB_KEYS)
        name = table.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError(f"job #{index}: name must be a non-empty string")
        if name in seen:
            raise ValueError(f"{name}: duplicate job name")
        seen.add(name)
        jobs.append(
            Job(
                name=name,
                timeout=_timeout(table.get("timeout", timeout), name),
                retries=_retries(table.get("retries", retries), name),
                tags=_tags(table.get("tags", []), name),
            )
        )
    return jobs


async def _run_one(
    job: Job, work: Callable[[Job], Awaitable[str]], slots: asyncio.Semaphore
) -> Result:
    async with slots:
        status: Status = "failed"
        output: str | None = None
        error: str | None = None
        attempts = 0
        while attempts <= job.retries:
            attempts += 1
            output = error = None
            try:
                async with asyncio.timeout(job.timeout):
                    output = await work(job)
            except TimeoutError:
                status = "timeout"
            except Exception as exc:
                status, error = "failed", f"{type(exc).__name__}: {exc}"
            else:
                status = "ok"
                break
        return Result(
            name=job.name,
            status=status,
            attempts=attempts,
            output=output,
            error=error,
            finished_at=datetime.now(UTC),
        )


async def run_jobs(
    jobs: Sequence[Job], work: Callable[[Job], Awaitable[str]], limit: int
) -> list[Result]:
    if limit < 1:
        raise ValueError("limit must be at least 1")
    slots = asyncio.Semaphore(limit)
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(_run_one(job, work, slots)) for job in jobs]
    return [task.result() for task in tasks]


def summarize(results: Iterable[Result]) -> dict[str, int]:
    counts = {"ok": 0, "failed": 0, "timeout": 0}
    for result in results:
        counts[result.status] += 1
    return counts
