#!/usr/bin/env bash
set -uo pipefail

echo "==> format"
if ! ruff format --check .; then
  echo "run: ruff format ."
  exit 1
fi

echo "==> lint"
ruff check . || exit 1

echo "==> build"
mypy jobs.py || exit 1

echo "==> test"
pytest tests || exit 1
