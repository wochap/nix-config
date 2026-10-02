from collections.abc import Iterable


def merge_intervals(intervals: Iterable[tuple[int, int]]) -> list[tuple[int, int]]:
    items = list(intervals)
    for start, end in items:
        if start > end:
            raise ValueError(f"invalid interval: ({start}, {end})")
    merged: list[tuple[int, int]] = []
    for start, end in sorted(items):
        if merged and start <= merged[-1][1]:
            last_start, last_end = merged[-1]
            merged[-1] = (last_start, max(last_end, end))
        else:
            merged.append((start, end))
    return merged
