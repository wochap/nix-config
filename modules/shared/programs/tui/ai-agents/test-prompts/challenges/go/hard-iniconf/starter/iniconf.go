// Package iniconf parses INI-style configuration files.
package iniconf

import (
	"errors"
	"io"
	"iter"
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

func (e *ParseError) Error() string { return "TODO" }

// Config holds parsed key/value pairs.
type Config struct{}

// Parse reads a config from r.
func Parse(r io.Reader) (*Config, error) {
	_ = r
	return &Config{}, nil
}

// Get returns the value for key.
func (c *Config) Get(key string) (string, bool) {
	_ = key
	return "", false
}

// Len returns the number of keys.
func (c *Config) Len() int { return 0 }

// Keys yields all keys in ascending order.
func (c *Config) Keys() iter.Seq[string] {
	return func(yield func(string) bool) {}
}

// All yields key/value pairs sorted by key.
func (c *Config) All() iter.Seq2[string, string] {
	return func(yield func(string, string) bool) {}
}

// Int returns the value for key parsed as an int.
func (c *Config) Int(key string) (int, error) {
	_ = key
	return 0, nil
}
