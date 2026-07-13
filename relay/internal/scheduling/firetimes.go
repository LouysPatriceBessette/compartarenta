// Package scheduling computes housing payment reminder fire instants.
package scheduling

import "time"

const localFireHour = 14

// BeforeDateDayOffsets returns calendar-day offsets k for J−k at 14:00 local.
// Offset 0 is the due date J itself (due-day reminder), always included.
func BeforeDateDayOffsets(recurrencePeriodDays int) []int {
	switch {
	case recurrencePeriodDays < 20:
		return []int{2, 0}
	case recurrencePeriodDays <= 40:
		return []int{4, 2, 0}
	default:
		return []int{6, 2, 0}
	}
}

// LocalFireAt returns 14:00:00 on calendarDate in loc.
func LocalFireAt(calendarDate time.Time, loc *time.Location) time.Time {
	y, m, d := calendarDate.Date()
	return time.Date(y, m, d, localFireHour, 0, 0, 0, loc)
}

// DueCalendarDate is the calendar date of dueAt in loc.
func DueCalendarDate(dueAt time.Time, loc *time.Location) time.Time {
	d := dueAt.In(loc)
	y, m, day := d.Date()
	return time.Date(y, m, day, 0, 0, 0, 0, loc)
}

// HousingBeforeDateFiresUTC returns UTC instants for before-date reminders.
// Skips fires strictly before materializeAfter.
func HousingBeforeDateFiresUTC(
	dueAt time.Time,
	recurrencePeriodDays int,
	loc *time.Location,
	materializeAfter time.Time,
) []time.Time {
	if loc == nil {
		return nil
	}
	j := DueCalendarDate(dueAt, loc)
	var out []time.Time
	for _, k := range BeforeDateDayOffsets(recurrencePeriodDays) {
		fireLocal := LocalFireAt(j.AddDate(0, 0, -k), loc)
		if !fireLocal.After(materializeAfter) {
			continue
		}
		out = append(out, fireLocal.UTC())
	}
	return out
}

// HousingOverdueFireUTC is 14:00 local on the day after J.
func HousingOverdueFireUTC(
	dueAt time.Time,
	loc *time.Location,
	materializeAfter time.Time,
) (time.Time, bool) {
	if loc == nil {
		return time.Time{}, false
	}
	j := DueCalendarDate(dueAt, loc)
	fireLocal := LocalFireAt(j.AddDate(0, 0, 1), loc)
	if !fireLocal.After(materializeAfter) {
		return time.Time{}, false
	}
	return fireLocal.UTC(), true
}
