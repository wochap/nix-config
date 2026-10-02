package tests

import (
	"slices"
	"testing"

	"example.com/wordfreq"
)

func TestTopWords(t *testing.T) {
	cases := []struct {
		name string
		text string
		n    int
		want []string
	}{
		{"basic", "the cat and the hat", 2, []string{"the", "and"}},
		{"ties alphabetical", "B a b A c", 3, []string{"a", "b", "c"}},
		{"unicode", "Ünïcode, ünïcode! x2 x2 x2", 5, []string{"x2", "ünïcode"}},
		{"fewer than n", "one two", 10, []string{"one", "two"}},
		{"punctuation only", "... ,,, !!!", 3, []string{}},
		{"empty", "", 3, []string{}},
		{"zero n", "a a b", 0, []string{}},
		{"negative n", "a a b", -1, []string{}},
		{"separators", "a-b_c\td\ne", 5, []string{"a", "b", "c", "d", "e"}},
		{"counts", "z z z y y x w w w w", 3, []string{"w", "z", "y"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := wordfreq.TopWords(tc.text, tc.n)
			if got == nil {
				t.Fatalf("TopWords(%q, %d) returned nil, want %q", tc.text, tc.n, tc.want)
			}
			if !slices.Equal(got, tc.want) {
				t.Fatalf("TopWords(%q, %d) = %q, want %q", tc.text, tc.n, got, tc.want)
			}
		})
	}
}
