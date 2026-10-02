#!/usr/bin/env bash
set -uo pipefail
export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
export GOCACHE="${GOCACHE:-$PWD/.cache/go-build}" GOPATH="${GOPATH:-$PWD/.cache/gopath}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.cache}"

echo "==> format"
unformatted=$(gofmt -l . 2>&1 | grep -v '^\.cache/')
if [[ -n "$unformatted" ]]; then
  echo "$unformatted"
  echo "run: gofmt -w ."
  exit 1
fi

echo "==> lint"
go vet ./... || exit 1
staticcheck ./... || exit 1

echo "==> build"
go build ./... || exit 1

echo "==> test"
go test -count=1 ./... || exit 1
