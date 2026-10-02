import asyncio
import dataclasses
import time
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest

from jobs import Job, Result, load_jobs, run_jobs, summarize


def write(tmp_path: Path, text: str) -> Path:
    path = tmp_path / "jobs.toml"
    path.write_text(text, encoding="utf-8")
    return path


def job(name: str, timeout: float = 1.0, retries: int = 0) -> Job:
    return Job(name=name, timeout=timeout, retries=retries)


# --- data types -------------------------------------------------------------


def test_job_is_frozen_slotted_kw_only() -> None:
    j = Job(name="a", timeout=1.0, retries=0)
    assert j.tags == ()
    with pytest.raises(dataclasses.FrozenInstanceError):
        j.name = "b"  # type: ignore[misc]
    assert not hasattr(j, "__dict__")
    with pytest.raises(TypeError):
        Job("a", 1.0, 0)  # type: ignore[misc]


def test_result_is_frozen_slotted() -> None:
    r = Result(
        name="a",
        status="ok",
        attempts=1,
        output="x",
        error=None,
        finished_at=datetime.now(UTC),
    )
    with pytest.raises(dataclasses.FrozenInstanceError):
        r.attempts = 2  # type: ignore[misc]
    assert not hasattr(r, "__dict__")


# --- load_jobs --------------------------------------------------------------


def test_load_with_defaults(tmp_path: Path) -> None:
    path = write(
        tmp_path,
        """
[defaults]
timeout = 2
retries = 1

[[job]]
name = "build"
timeout = 0.5
tags = ["ci", "fast"]

[[job]]
name = "test"
retries = 0
""",
    )
    jobs = load_jobs(path)
    assert jobs == [
        Job(name="build", timeout=0.5, retries=1, tags=("ci", "fast")),
        Job(name="test", timeout=2.0, retries=0),
    ]
    assert type(jobs[1].timeout) is float


def test_load_builtin_defaults(tmp_path: Path) -> None:
    jobs = load_jobs(write(tmp_path, '[[job]]\nname = "only"\n'))
    assert jobs == [Job(name="only", timeout=1.0, retries=0, tags=())]


def test_load_empty(tmp_path: Path) -> None:
    assert load_jobs(write(tmp_path, "")) == []
    assert load_jobs(write(tmp_path, "[defaults]\nretries = 3\n")) == []


@pytest.mark.parametrize(
    ("text", "needle"),
    [
        ("[[job]\nname = 'x'", None),
        ("other = 1", None),
        ("[defaults]\nfoo = 1", None),
        ("[defaults]\ntimeout = 0", None),
        ("[[job]]\ntimeout = 1.0", None),
        ("[[job]]\nname = ''", None),
        ("[[job]]\nname = 'dup'\n[[job]]\nname = 'dup'", "dup"),
        ("[[job]]\nname = 'neg'\ntimeout = -1", "neg"),
        ("[[job]]\nname = 'str'\ntimeout = 'fast'", "str"),
        ("[[job]]\nname = 'flt'\nretries = 1.5", "flt"),
        ("[[job]]\nname = 'boo'\nretries = true", "boo"),
        ("[[job]]\nname = 'btm'\ntimeout = true", "btm"),
        ("[[job]]\nname = 'rneg'\nretries = -1", "rneg"),
        ("[[job]]\nname = 'tg'\ntags = 'ci'", "tg"),
        ("[[job]]\nname = 'tg2'\ntags = ['a', 1]", "tg2"),
        ("[[job]]\nname = 'unk'\ncolor = 'red'", "unk"),
    ],
)
def test_load_invalid(tmp_path: Path, text: str, needle: str | None) -> None:
    with pytest.raises(ValueError, match=needle):
        load_jobs(write(tmp_path, text))


# --- run_jobs ---------------------------------------------------------------


def test_run_ok_in_order() -> None:
    async def work(j: Job) -> str:
        await asyncio.sleep(0.03 if j.name == "a" else 0.0)
        return j.name.upper()

    before = datetime.now(UTC)
    results = asyncio.run(run_jobs([job("a"), job("b"), job("c")], work, 3))
    assert [r.name for r in results] == ["a", "b", "c"]
    assert [r.output for r in results] == ["A", "B", "C"]
    assert all(r.status == "ok" and r.attempts == 1 for r in results)
    assert all(r.error is None for r in results)
    for r in results:
        assert r.finished_at.utcoffset() == timedelta(0)
        assert before <= r.finished_at <= datetime.now(UTC)
    assert results[0].finished_at >= results[1].finished_at


def test_run_retries_until_success() -> None:
    calls: dict[str, int] = {}

    async def work(j: Job) -> str:
        calls[j.name] = calls.get(j.name, 0) + 1
        if calls[j.name] < 3:
            raise RuntimeError(f"try {calls[j.name]}")
        return "done"

    results = asyncio.run(run_jobs([job("flaky", retries=5)], work, 1))
    assert results[0].status == "ok"
    assert results[0].attempts == 3
    assert results[0].output == "done"
    assert results[0].error is None


def test_run_failure_keeps_others_going() -> None:
    async def work(j: Job) -> str:
        if j.name == "bad":
            raise KeyError("missing")
        await asyncio.sleep(0.02)
        return "fine"

    jobs = [job("bad", retries=1), job("good")]
    results = asyncio.run(run_jobs(jobs, work, 2))
    bad, good = results
    assert bad.status == "failed"
    assert bad.attempts == 2
    assert bad.output is None
    assert bad.error == "KeyError: 'missing'"
    assert good.status == "ok"
    assert good.output == "fine"


def test_run_timeout_cancels_attempt() -> None:
    cancelled: list[str] = []

    async def work(j: Job) -> str:
        try:
            await asyncio.sleep(5)
        except asyncio.CancelledError:
            cancelled.append(j.name)
            raise
        return "late"

    start = time.monotonic()
    results = asyncio.run(run_jobs([job("slow", timeout=0.05, retries=2)], work, 1))
    elapsed = time.monotonic() - start
    assert results[0].status == "timeout"
    assert results[0].attempts == 3
    assert results[0].output is None
    assert results[0].error is None
    assert cancelled == ["slow", "slow", "slow"]
    assert elapsed < 1.0


def test_run_timeout_then_success() -> None:
    calls: list[int] = []

    async def work(j: Job) -> str:
        calls.append(1)
        await asyncio.sleep(1 if len(calls) == 1 else 0)
        return "second"

    results = asyncio.run(run_jobs([job("t", timeout=0.05, retries=1)], work, 1))
    assert (results[0].status, results[0].attempts) == ("ok", 2)
    assert results[0].output == "second"


def test_run_respects_limit() -> None:
    running = 0
    peak = 0

    async def work(j: Job) -> str:
        nonlocal running, peak
        running += 1
        peak = max(peak, running)
        await asyncio.sleep(0.1)
        running -= 1
        return j.name

    start = time.monotonic()
    jobs = [job(str(i)) for i in range(6)]
    results = asyncio.run(run_jobs(jobs, work, 2))
    elapsed = time.monotonic() - start
    assert peak == 2
    assert [r.output for r in results] == [str(i) for i in range(6)]
    assert 0.28 <= elapsed < 0.6


def test_run_empty_and_bad_limit() -> None:
    async def work(j: Job) -> str:
        return j.name

    assert asyncio.run(run_jobs([], work, 1)) == []
    with pytest.raises(ValueError):
        asyncio.run(run_jobs([job("a")], work, 0))


# --- summarize --------------------------------------------------------------


def test_summarize() -> None:
    now = datetime.now(UTC)

    def res(status: str) -> Result:
        return Result(
            name=status,
            status=status,  # type: ignore[arg-type]
            attempts=1,
            output=None,
            error=None,
            finished_at=now,
        )

    assert summarize([]) == {"ok": 0, "failed": 0, "timeout": 0}
    got = summarize(res(s) for s in ["ok", "timeout", "ok", "failed"])
    assert got == {"ok": 2, "failed": 1, "timeout": 1}
