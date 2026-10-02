package tests

import (
	"errors"
	"slices"
	"strconv"
	"strings"
	"testing"
	"testing/iotest"

	"example.com/iniconf"
)

const sample = "# server\r\nname = demo\n[http]\nport = 8080\ngreeting = \"hi \\\"you\\\"\"\nport = 9090\nbad line\n"

func parseErrors(t *testing.T, err error) []*iniconf.ParseError {
	t.Helper()
	if err == nil {
		return nil
	}
	joined, ok := err.(interface{ Unwrap() []error })
	if !ok {
		t.Fatalf("error %v is not an errors.Join result", err)
	}
	var out []*iniconf.ParseError
	for _, e := range joined.Unwrap() {
		pe, ok := errors.AsType[*iniconf.ParseError](e)
		if !ok {
			t.Fatalf("joined error %v is not a *ParseError", e)
		}
		out = append(out, pe)
	}
	return out
}

func mustGet(t *testing.T, c *iniconf.Config, k, want string) {
	t.Helper()
	got, ok := c.Get(k)
	if !ok || got != want {
		t.Fatalf("Get(%q) = %q, %v; want %q, true", k, got, ok, want)
	}
}

func TestSample(t *testing.T) {
	c, err := iniconf.Parse(strings.NewReader(sample))
	if c == nil {
		t.Fatal("Parse returned nil config")
	}
	mustGet(t, c, "name", "demo")
	mustGet(t, c, "http.port", "8080")
	mustGet(t, c, "http.greeting", `hi "you"`)
	if c.Len() != 3 {
		t.Fatalf("Len() = %d, want 3", c.Len())
	}
	pes := parseErrors(t, err)
	if len(pes) != 2 {
		t.Fatalf("got %d parse errors (%v), want 2", len(pes), err)
	}
	if pes[0].Line != 6 || !errors.Is(pes[0], iniconf.ErrDuplicateKey) {
		t.Fatalf("first error = %v, want line 6 duplicate key", pes[0])
	}
	if pes[1].Line != 7 || !errors.Is(pes[1], iniconf.ErrSyntax) {
		t.Fatalf("second error = %v, want line 7 syntax error", pes[1])
	}
	if got := pes[0].Error(); got != "line 6: duplicate key" {
		t.Fatalf("Error() = %q", got)
	}
	if !errors.Is(err, iniconf.ErrSyntax) || !errors.Is(err, iniconf.ErrDuplicateKey) || errors.Is(err, iniconf.ErrBadKey) {
		t.Fatalf("errors.Is on joined error wrong: %v", err)
	}
	want := "line 6: duplicate key\nline 7: syntax error"
	if err.Error() != want {
		t.Fatalf("err.Error() = %q, want %q", err.Error(), want)
	}
}

func TestValid(t *testing.T) {
	in := strings.Join([]string{
		"  ; comment",
		"\t# another",
		"",
		"a=1",
		"empty =",
		"eq = x=y",
		`  spaced = "  a "  `,
		`esc = "back\\slash\nnl"`,
		"[db-main]",
		"user_1 = root",
		"[z]",
		"a = last",
	}, "\n")
	c, err := iniconf.Parse(strings.NewReader(in))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	mustGet(t, c, "a", "1")
	mustGet(t, c, "empty", "")
	mustGet(t, c, "eq", "x=y")
	mustGet(t, c, "spaced", "  a ")
	mustGet(t, c, "esc", "back\\slash\nnl")
	mustGet(t, c, "db-main.user_1", "root")
	mustGet(t, c, "z.a", "last")
	if _, ok := c.Get("user_1"); ok {
		t.Fatal("key without section prefix should not exist")
	}
	keys := slices.Collect(c.Keys())
	wantKeys := []string{"a", "db-main.user_1", "empty", "eq", "esc", "spaced", "z.a"}
	if !slices.Equal(keys, wantKeys) {
		t.Fatalf("Keys() = %q, want %q", keys, wantKeys)
	}
	var pairs []string
	for k, v := range c.All() {
		pairs = append(pairs, k+"="+v)
		if len(pairs) == 2 {
			break
		}
	}
	if !slices.Equal(pairs, []string{"a=1", "db-main.user_1=root"}) {
		t.Fatalf("All() with break = %q", pairs)
	}
	n := 0
	for range c.Keys() {
		n++
		if n == 3 {
			break
		}
	}
	if n != 3 {
		t.Fatalf("Keys() break: n = %d", n)
	}
}

func TestErrorKinds(t *testing.T) {
	cases := []struct {
		line string
		want error
	}{
		{"foo", iniconf.ErrSyntax},
		{"= v", iniconf.ErrBadKey},
		{"Key = v", iniconf.ErrBadKey},
		{"k y = v", iniconf.ErrBadKey},
		{"[Bad]", iniconf.ErrBadKey},
		{"[]", iniconf.ErrBadKey},
		{"[x", iniconf.ErrSyntax},
		{`k = "open`, iniconf.ErrSyntax},
		{`k = "a"b"`, iniconf.ErrSyntax},
		{`k = "bad \t escape"`, iniconf.ErrSyntax},
		{`k = "trailing\"`, iniconf.ErrSyntax},
		{`k = "`, iniconf.ErrSyntax},
	}
	for _, tc := range cases {
		c, err := iniconf.Parse(strings.NewReader("ok = 1\n" + tc.line + "\n"))
		if c == nil {
			t.Fatalf("%q: nil config", tc.line)
		}
		pes := parseErrors(t, err)
		if len(pes) != 1 || pes[0].Line != 2 || !errors.Is(pes[0], tc.want) {
			t.Fatalf("%q: got %v, want line 2: %v", tc.line, err, tc.want)
		}
		if c.Len() != 1 {
			t.Fatalf("%q: Len() = %d, want 1", tc.line, c.Len())
		}
	}
}

func TestBadSectionKeepsPrevious(t *testing.T) {
	c, err := iniconf.Parse(strings.NewReader("[a]\n[B]\nk = v\n"))
	if len(parseErrors(t, err)) != 1 {
		t.Fatalf("want 1 error, got %v", err)
	}
	mustGet(t, c, "a.k", "v")
}

func TestInt(t *testing.T) {
	c, err := iniconf.Parse(strings.NewReader("n = 42\nneg = -7\nbad = 4x\n"))
	if err != nil {
		t.Fatal(err)
	}
	if v, err := c.Int("n"); err != nil || v != 42 {
		t.Fatalf("Int(n) = %d, %v", v, err)
	}
	if v, err := c.Int("neg"); err != nil || v != -7 {
		t.Fatalf("Int(neg) = %d, %v", v, err)
	}
	_, err = c.Int("missing_key")
	if !errors.Is(err, iniconf.ErrNotFound) || !strings.Contains(err.Error(), "missing_key") {
		t.Fatalf("Int(missing_key) err = %v", err)
	}
	_, err = c.Int("bad")
	ne, ok := errors.AsType[*strconv.NumError](err)
	if !ok || ne.Num != "4x" {
		t.Fatalf("Int(bad) err = %v, want wrapped *strconv.NumError", err)
	}
}

func TestEmpty(t *testing.T) {
	c, err := iniconf.Parse(strings.NewReader(""))
	if err != nil || c == nil || c.Len() != 0 {
		t.Fatalf("empty input: %v %v", c, err)
	}
	if len(slices.Collect(c.Keys())) != 0 {
		t.Fatal("empty Keys")
	}
}

func TestReadError(t *testing.T) {
	boom := errors.New("boom")
	_, err := iniconf.Parse(iotest.ErrReader(boom))
	if !errors.Is(err, boom) {
		t.Fatalf("read error = %v, want boom", err)
	}
}
