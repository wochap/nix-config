import pytest

from intervals import merge_intervals


def test_empty() -> None:
    assert merge_intervals([]) == []


def test_disjoint_sorted() -> None:
    assert merge_intervals([(1, 2), (4, 5)]) == [(1, 2), (4, 5)]


def test_overlapping_unsorted() -> None:
    assert merge_intervals([(8, 10), (1, 3), (2, 6), (15, 18)]) == [
        (1, 6),
        (8, 10),
        (15, 18),
    ]


def test_touching_and_contained() -> None:
    assert merge_intervals([(1, 3), (3, 5)]) == [(1, 5)]
    assert merge_intervals([(1, 10), (2, 3), (4, 5)]) == [(1, 10)]
    assert merge_intervals([(5, 5), (5, 5)]) == [(5, 5)]


def test_negative_and_points() -> None:
    assert merge_intervals([(-5, -1), (0, 0), (-2, 0)]) == [(-5, 0)]


def test_generator_input() -> None:
    gen = ((i, i + 1) for i in range(0, 10, 3))
    assert merge_intervals(gen) == [(0, 1), (3, 4), (6, 7), (9, 10)]


def test_input_not_modified() -> None:
    data = [(3, 4), (1, 2)]
    merge_intervals(data)
    assert data == [(3, 4), (1, 2)]


def test_result_items_are_tuples() -> None:
    result = merge_intervals([(1, 2), (2, 3)])
    assert all(type(item) is tuple for item in result)


def test_invalid_interval() -> None:
    with pytest.raises(ValueError):
        merge_intervals([(1, 2), (5, 4)])
