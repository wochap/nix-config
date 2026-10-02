// Package wordfreq counts word frequencies.
package wordfreq

import (
	"cmp"
	"maps"
	"slices"
	"strings"
	"unicode"
)

// TopWords returns the n most frequent words in text.
func TopWords(text string, n int) []string {
	counts := map[string]int{}
	for _, w := range strings.FieldsFunc(text, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	}) {
		counts[strings.ToLower(w)]++
	}
	words := slices.AppendSeq(make([]string, 0, len(counts)), maps.Keys(counts))
	slices.SortFunc(words, func(a, b string) int {
		if c := cmp.Compare(counts[b], counts[a]); c != 0 {
			return c
		}
		return strings.Compare(a, b)
	})
	return words[:max(0, min(n, len(words)))]
}
