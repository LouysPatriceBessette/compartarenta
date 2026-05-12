package store

import (
	"bytes"
	"testing"
)

func TestCanonicalPairIsCommutative(t *testing.T) {
	x := []byte{0x01, 0x02, 0x03}
	y := []byte{0xff, 0xfe, 0xfd}

	a1, b1 := canonicalPair(x, y)
	a2, b2 := canonicalPair(y, x)

	if !bytes.Equal(a1, a2) || !bytes.Equal(b1, b2) {
		t.Fatalf("canonicalPair is not commutative: (%x,%x) vs (%x,%x)", a1, b1, a2, b2)
	}
	if bytes.Compare(a1, b1) > 0 {
		t.Fatalf("canonical pair must have a < b lexicographically, got a=%x b=%x", a1, b1)
	}
}

func TestCompareBytesMatchesBytesCompare(t *testing.T) {
	cases := [][2][]byte{
		{{}, {}},
		{{0x00}, {}},
		{{0x00}, {0x00}},
		{{0x01, 0x02}, {0x01, 0x03}},
		{{0x01, 0x02, 0x03}, {0x01, 0x02}},
		{{0xff}, {0x01}},
	}
	for _, c := range cases {
		got := compareBytes(c[0], c[1])
		want := bytes.Compare(c[0], c[1])
		// We only require the SIGN to match, not the exact value.
		if sign(got) != sign(want) {
			t.Errorf("compareBytes(%x, %x) = %d, bytes.Compare = %d",
				c[0], c[1], got, want)
		}
	}
}

func sign(n int) int {
	switch {
	case n < 0:
		return -1
	case n > 0:
		return 1
	default:
		return 0
	}
}
