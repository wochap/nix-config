# go cartridge — target: Go 1.26

## Rules (DON'T → DO)
- DON'T `ioutil.ReadFile` / `ioutil.ReadAll` (deprecated) → DO `os.ReadFile` / `io.ReadAll`
- DON'T `ioutil.TempDir` / `ioutil.WriteFile` → DO `os.MkdirTemp` / `os.WriteFile`
- DON'T `fmt.Errorf("x: %v", err)` when callers inspect it → DO `fmt.Errorf("x: %w", err)`
- DON'T `err == ErrNotFound` on wrapped errors → DO `errors.Is(err, ErrNotFound)`
- DON'T type-assert `err.(*MyErr)` → DO `errors.As(err, &target)` or `e, ok := errors.AsType[*MyErr](err)` (1.26)
- DON'T hand-roll multi-error types → DO `errors.Join(err1, err2)`
- DON'T `x := v; p := &x` just to get a pointer → DO `p := new(v)` (new accepts an expression since 1.26)
- DON'T `for i := 0; i < n; i++` for simple counts → DO `for i := range n`
- DON'T copy loop vars `v := v` before closures → DO nothing; loop vars are per-iteration since 1.22
- DON'T write custom sort/contains/index helpers → DO `slices.Sort`, `slices.Contains`, `slices.Index`, `slices.SortFunc`
- DON'T `sort.Slice` in new code → DO `slices.SortFunc(s, func(a, b T) int { return cmp.Compare(a.X, b.X) })`
- DON'T loop to collect map keys → DO `slices.Sorted(maps.Keys(m))`
- DON'T write `func Max(a, b int)` helpers → DO builtins `min(a, b)`, `max(a, b)`
- DON'T loop-delete every map key → DO `clear(m)`
- DON'T `golang.org/x/exp/slices|maps|constraints` → DO std `slices`, `maps`, `cmp` (`cmp.Ordered`)
- DON'T `log.Printf` for structured logs → DO `slog.Info("msg", "key", val)`
- DON'T route manually with `r.Method` / `strings.Split(r.URL.Path)` → DO `mux.HandleFunc("GET /items/{id}", h)` and `r.PathValue("id")`
- DON'T `wg.Add(1); go func(){ defer wg.Done(); ... }()` → DO `wg.Go(func(){ ... })` (1.25)
- DON'T `strings.Split` when only iterating → DO `for part := range strings.SplitSeq(s, ",")`
- DON'T `for i := 0; i < b.N; i++` in benchmarks → DO `for b.Loop() { ... }`
- DON'T `context.Background()` inside tests → DO `t.Context()`
- DON'T store `context.Context` in a struct → DO pass `ctx context.Context` as first param
- DON'T `interface{}` → DO `any`
- DON'T panic for expected errors → DO return `error` as the last result
- DON'T `json:",omitempty"` on struct/time.Time fields (never omitted) → DO `json:",omitzero"`

## Gotchas
- `:=` in an inner scope shadows the outer var; `err` assigned inside `if` is not the outer `err`.
- Writing to a nil map panics; init with `make(map[K]V)` or a literal.
- A nil slice and an empty slice both have len 0; nil marshals to JSON `null`, empty to `[]`.
- `append` may reuse the backing array; two slices from one base can overwrite each other.
- Use `s2 := slices.Clone(s)` or full slice `s[:n:n]` to avoid append aliasing.
- `defer` in a loop runs at function return, not per iteration; wrap the body in a func.
- Deferred call args are evaluated when `defer` runs, not at return.
- A nil `*T` stored in an `error` interface is non-nil; return literal `nil`.
- Ranging over a map has random order; sort keys for stable output.
- `range` over a string yields runes and byte offsets, not byte indexes 0..n.
- Goroutine leak: always give blocked goroutines a `ctx.Done()` or closed-channel exit.
- Sending on a closed channel panics; only the sender closes.
- `sync.Mutex` must not be copied; pass structs containing it by pointer.
- `time.After` in a loop allocates timers; prefer `time.NewTicker` or a `ctx` timeout.
- Method values on value receivers copy the struct; use pointer receivers for mutation.
- Unused imports and unused local variables are compile errors.
- Generic methods cannot have their own type params; only the type and funcs can.
- `iter.Seq[V]` is `func(yield func(V) bool)`; stop when `yield` returns false.
- Always `defer resp.Body.Close()` after a successful `http.Get`/`Do`.
- Default `http.Client` has no timeout; set `Timeout` explicitly.

## Correct API names
- `ioutil.*` → `os.ReadFile`, `os.WriteFile`, `io.ReadAll`, `os.ReadDir`, `os.MkdirTemp`, `os.CreateTemp`
- `sort.Ints(s)` → `slices.Sort(s)`
- `strings.Title` (deprecated) → `cases.Title` from `golang.org/x/text/cases`
- `constraints.Ordered` → `cmp.Ordered`
- `maps.Keys` returns `iter.Seq[K]`, not a slice; wrap with `slices.Collect` or `slices.Sorted`
- `rand.Seed` (deprecated) → no seeding needed; or `math/rand/v2`
- `errors.AsType[T](err)` returns `(T, bool)` (1.26)
- `r.PathValue("id")` reads `{id}` wildcards; `{path...}` matches the rest
- `sync.OnceValue(f)` / `sync.OnceFunc(f)` instead of `sync.Once` + var
- `os.OpenRoot(dir)` for path-traversal-safe file access
- `testing/synctest.Test(t, f)` for fake-time concurrency tests
- `go fix ./...` applies modernizers (1.26); not the old `gofix`

## Idioms
```go
func Load(ctx context.Context, id string) (*Item, error) {
	it, err := db.Get(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("load %s: %w", id, err)
	}
	return it, nil
}
```
```go
func Count(n int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := range n {
			if !yield(i) { return }
		}
	}
}
```
```go
func Max[T cmp.Ordered](xs ...T) T { return slices.Max(xs) }
```
```go
mux := http.NewServeMux()
mux.HandleFunc("GET /items/{id}", func(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, r.PathValue("id"))
})
```
```go
var wg sync.WaitGroup
for _, u := range urls { wg.Go(func() { fetch(u) }) }
wg.Wait()
```

## Tooling
- `go mod init example.com/app` / `go mod tidy` (after adding/removing imports)
- `go get pkg@latest` to add/upgrade a dep; `go install pkg@version` for tools
- `go build ./...` / `go run .`
- `go test ./...` / `go test -race ./...` / `go test -run TestName -v ./pkg`
- `go test -bench . -benchmem`
- `go vet ./...` (always run before committing)
- `gofmt -w .` or `go fmt ./...`; `goimports -w .` also fixes imports
- `go fix ./...` to modernize code; `go fix -diff ./...` to preview
- `staticcheck ./...` / `golangci-lint run` if available
- `go.mod` `go 1.26` line gates language features
