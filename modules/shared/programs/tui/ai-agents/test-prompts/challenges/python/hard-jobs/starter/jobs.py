from collections.abc import Awaitable, Callable, Iterable, Sequence
from pathlib import Path


class Job:
    pass


class Result:
    pass


def load_jobs(path: Path) -> list[Job]:
    raise NotImplementedError


async def run_jobs(
    jobs: Sequence[Job], work: Callable[[Job], Awaitable[str]], limit: int
) -> list[Result]:
    raise NotImplementedError


def summarize(results: Iterable[Result]) -> dict[str, int]:
    raise NotImplementedError
