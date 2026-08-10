package evaluator

import "../object"
import "../types"
import "core:time"

eval_time :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	type := syntax.value.token.literal
	tz_offset_seconds: i64 = 2 * 3600
	utc_now := time.now()
	local_now := time.Time {
		_nsec = utc_now._nsec + (tz_offset_seconds * 1_000_000_000),
	}
	dt, _ := time.time_to_datetime(local_now)
	switch type {
	case "year", "years":
		return object.create_int(int(dt.year))

	case "month", "months":
		return object.create_int(int(dt.month))

	case "day", "days":
		return object.create_int(int(dt.day))

	case "hour", "hours":
		return object.create_int(int(dt.hour))

	case "minute", "minutes":
		return object.create_int(int(dt.minute))

	case "second", "seconds":
		return object.create_int(int(dt.second))

	case "millisecond", "milliseconds":
		return object.create_int(int(dt.nano / 1_000_000))

	case "microsecond", "microseconds":
		return object.create_int(int(dt.nano / 1_000))

	case "nanosecond", "nanoseconds", "nano":
		return object.create_int(int(dt.nano))
	case "weekday":
		weekday := calculate_day_of_week(int(dt.year), int(dt.month), int(dt.day))
		return object.create_string(weekday)
	case "day_of_week":
		weekday := calculate_day_of_week(int(dt.year), int(dt.month), int(dt.day))
		switch (weekday) {
		case "monday":
			return object.create_int(0)
		case "tuesday":
			return object.create_int(1)
		case "wednesday":
			return object.create_int(2)
		case "thursday":
			return object.create_int(3)
		case "friday":
			return object.create_int(4)
		case "saturday":
			return object.create_int(5)
		case "sunday":
			return object.create_int(6)
		}
		return object.create_null()
	case "day_of_year", "year_day":
		doy := calculate_day_of_year(int(dt.year), int(dt.month), int(dt.day))
		return object.create_int(doy)
	case:
		return nil, .ERROR
	}
}

is_leap_year :: proc(year: int) -> bool {
	return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

calculate_day_of_week :: proc(year, month, day: int) -> string {
	t := [12]int{0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
	y := year
	if month < 3 {
		y -= 1
	}
	switch ((y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7) {
	case 0:
		return "monday"
	case 1:
		return "tuesday"
	case 2:
		return "wednesday"
	case 3:
		return "thursday"
	case 4:
		return "friday"
	case 5:
		return "saturday"
	case 6:
		return "sunday"
	case:
		return ""
	}
}

calculate_day_of_year :: proc(year, month, day: int) -> int {
	days_before_month := [12]int{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}
	doy := days_before_month[month - 1] + day
	if month > 2 && is_leap_year(year) {
		doy += 1
	}
	return doy
}
