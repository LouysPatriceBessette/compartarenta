package scheduling

import (
	"testing"
	"time"
)

func TestBeforeDateDayOffsets(t *testing.T) {
	if got := BeforeDateDayOffsets(14); len(got) != 1 || got[0] != 2 {
		t.Fatalf("W=14: got %v", got)
	}
	if got := BeforeDateDayOffsets(30); len(got) != 2 || got[0] != 4 || got[1] != 2 {
		t.Fatalf("W=30: got %v", got)
	}
	if got := BeforeDateDayOffsets(45); len(got) != 2 || got[0] != 6 || got[1] != 2 {
		t.Fatalf("W=45: got %v", got)
	}
}

func TestHousingBeforeDateFires_JulyExample(t *testing.T) {
	loc, err := time.LoadLocation("America/Toronto")
	if err != nil {
		t.Fatal(err)
	}
	// J = 2026-07-20
	dueAt := time.Date(2026, 7, 20, 9, 0, 0, 0, loc)
	mat := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	fires := HousingBeforeDateFiresUTC(dueAt, 30, loc, mat)
	if len(fires) != 2 {
		t.Fatalf("expected 2 fires, got %d", len(fires))
	}
	j4 := time.Date(2026, 7, 16, 14, 0, 0, 0, loc).UTC()
	j2 := time.Date(2026, 7, 18, 14, 0, 0, 0, loc).UTC()
	if !fires[0].Equal(j4) {
		t.Fatalf("J-4: got %v want %v", fires[0], j4)
	}
	if !fires[1].Equal(j2) {
		t.Fatalf("J-2: got %v want %v", fires[1], j2)
	}
}

func TestHousingBeforeDateFires_NotMidnight(t *testing.T) {
	loc := time.FixedZone("X", -4*3600)
	dueAt := time.Date(2026, 7, 20, 0, 0, 0, 0, loc)
	mat := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	fires := HousingBeforeDateFiresUTC(dueAt, 14, loc, mat)
	if len(fires) != 1 {
		t.Fatalf("got %d fires", len(fires))
	}
	local := fires[0].In(loc)
	if local.Hour() != 14 || local.Minute() != 0 {
		t.Fatalf("expected 14:00 local, got %v", local)
	}
}
