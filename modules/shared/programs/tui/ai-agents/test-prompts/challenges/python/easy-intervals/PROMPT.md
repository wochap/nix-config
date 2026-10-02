# Merge intervals

Implement `intervals.py` (Python 3.13) with:

```python
def merge_intervals(intervals: Iterable[tuple[int, int]]) -> list[tuple[int, int]]: ...
```

- Each interval `(start, end)` is closed: it includes both ends.
- Merge all intervals that overlap or touch (`(1, 3)` and `(3, 5)` become
  `(1, 5)`). Return the merged intervals as tuples sorted by start.
- The input can be in any order and can be any iterable (for example a
  generator, which can only be read once). Do not modify the input.
- If any interval has `start > end`, raise `ValueError`.

```python
merge_intervals([(8, 10), (1, 3), (2, 6), (15, 18)])  # [(1, 6), (8, 10), (15, 18)]
merge_intervals([(1, 3), (3, 5)])                     # [(1, 5)]
merge_intervals([])                                   # []
```

The code must pass `ruff format --check`, `ruff check` and `mypy` in strict
mode (config in `pyproject.toml`). Tests: `pytest tests`.
