// Package iniconf parses INI-style configuration files.
package iniconf

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"iter"
	"maps"
	"slices"
	"strconv"
	"strings"
)

// Sentinel errors.
var (
	ErrSyntax       = errors.New("syntax error")
	ErrBadKey       = errors.New("invalid key")
	ErrDuplicateKey = errors.New("duplicate key")
	ErrNotFound     = errors.New("key not found")
)

// ParseError reports a bad line.
type ParseError struct {
	Line int
	Err  error
}

func (e *ParseError) Error() string { return fmt.Sprintf("line %d: %v", e.Line, e.Err) }

// Unwrap returns the underlying sentinel error.
func (e *ParseError) Unwrap() error { return e.Err }

// Config holds parsed key/value pairs.
type Config struct {
	values map[string]string
}

func validKey(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if !(r >= 'a' && r <= 'z' || r >= '0' && r <= '9' || r == '_' || r == '-') {
			return false
		}
	}
	return true
}

func unquote(s string) (string, bool) {
	if len(s) < 2 || s[len(s)-1] != '"' {
		return "", false
	}
	inner := s[1 : len(s)-1]
	var b strings.Builder
	for i := 0; i < len(inner); i++ {
		c := inner[i]
		switch c {
		case '"':
			return "", false
		case '\\':
			i++
			if i >= len(inner) {
				return "", false
			}
			switch inner[i] {
			case '"', '\\':
				b.WriteByte(inner[i])
			case 'n':
				b.WriteByte('\n')
			default:
				return "", false
			}
		default:
			b.WriteByte(c)
		}
	}
	return b.String(), true
}

// Parse reads a config from r.
func Parse(r io.Reader) (*Config, error) {
	c := &Config{values: map[string]string{}}
	var errs []error
	section := ""
	sc := bufio.NewScanner(r)
	lineNo := 0
	fail := func(err error) { errs = append(errs, &ParseError{Line: lineNo, Err: err}) }
	for sc.Scan() {
		lineNo++
		line := strings.Trim(sc.Text(), " \t\r")
		switch {
		case line == "" || line[0] == '#' || line[0] == ';':
			continue
		case line[0] == '[':
			name, ok := strings.CutPrefix(line, "[")
			name, ok2 := strings.CutSuffix(name, "]")
			if !ok || !ok2 {
				fail(ErrSyntax)
			} else if !validKey(name) {
				fail(ErrBadKey)
			} else {
				section = name
			}
			continue
		}
		k, v, ok := strings.Cut(line, "=")
		if !ok {
			fail(ErrSyntax)
			continue
		}
		k, v = strings.Trim(k, " \t"), strings.Trim(v, " \t")
		if !validKey(k) {
			fail(ErrBadKey)
			continue
		}
		if strings.HasPrefix(v, `"`) {
			if v, ok = unquote(v); !ok {
				fail(ErrSyntax)
				continue
			}
		}
		if section != "" {
			k = section + "." + k
		}
		if _, dup := c.values[k]; dup {
			fail(ErrDuplicateKey)
			continue
		}
		c.values[k] = v
	}
	if err := sc.Err(); err != nil {
		return c, fmt.Errorf("read config: %w", err)
	}
	return c, errors.Join(errs...)
}

// Get returns the value for key.
func (c *Config) Get(key string) (string, bool) {
	v, ok := c.values[key]
	return v, ok
}

// Len returns the number of keys.
func (c *Config) Len() int { return len(c.values) }

// Keys yields all keys in ascending order.
func (c *Config) Keys() iter.Seq[string] {
	return slices.Values(slices.Sorted(maps.Keys(c.values)))
}

// All yields key/value pairs sorted by key.
func (c *Config) All() iter.Seq2[string, string] {
	return func(yield func(string, string) bool) {
		for k := range c.Keys() {
			if !yield(k, c.values[k]) {
				return
			}
		}
	}
}

// Int returns the value for key parsed as an int.
func (c *Config) Int(key string) (int, error) {
	v, ok := c.values[key]
	if !ok {
		return 0, fmt.Errorf("%w: %s", ErrNotFound, key)
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return 0, fmt.Errorf("key %s: %w", key, err)
	}
	return n, nil
}
