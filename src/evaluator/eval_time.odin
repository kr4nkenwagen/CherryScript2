package evaluator

import "../object"
import "../types"
import "core:time"
import "core:time/datetime"

eval_time :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
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
	case "month_name":
		return object.create_string(calculate_month_name(int(dt.month)))
	case "month_short_name":
		return object.create_string(calculate_short_month_name(int(dt.month)))
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
		weekday_num := calculate_weekday_number(dt)
		if weekday_num == -1 do return object.create_null()
		return object.create_int(weekday_num)
	case "day_of_year", "year_day":
		doy := calculate_day_of_year(int(dt.year), int(dt.month), int(dt.day))
		return object.create_int(doy)
	case "execution_time":
		elapsed := time.tick_since(g_start_time_execution^)
		seconds := time.duration_seconds(elapsed)
		return object.create_float(f32(seconds))
	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_TIME
	}
	return
}

calculate_weekday_number :: proc(dt: datetime.DateTime) -> int {
	weekday := calculate_day_of_week(int(dt.year), int(dt.month), int(dt.day))
	switch (weekday) {
	case "monday":
		return 0
	case "tuesday":
		return 1
	case "wednesday":
		return 2
	case "thursday":
		return 3
	case "friday":
		return 4
	case "saturday":
		return 5
	case "sunday":
		return 6
	}
	return -1
}

calculate_short_month_name :: proc(month: int) -> string {
	switch month {
	case 0:
		return "jan"
	case 1:
		return "feb"
	case 2:
		return "march"
	case 3:
		return "april"
	case 4:
		return "may"
	case 5:
		return "june"
	case 6:
		return "july"
	case 7:
		return "aug"
	case 8:
		return "sep"
	case 9:
		return "oct"
	case 10:
		return "nov"
	case 11:
		return "dec"
	}
	return ""
}

calculate_month_name :: proc(month: int) -> string {
	switch month {
	case 0:
		return "january"
	case 1:
		return "february"
	case 2:
		return "march"
	case 3:
		return "april"
	case 4:
		return "may"
	case 5:
		return "june"
	case 6:
		return "july"
	case 7:
		return "august"
	case 8:
		return "september"
	case 9:
		return "october"
	case 10:
		return "november"
	case 11:
		return "december"
	}
	return ""
}

is_leap_year :: proc(year: int) -> bool {
	return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

calculate_day_of_week :: proc(year, month, day: int) -> string {
	t := [12]int{0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
	y := year
	if month < 3 do y -= 1
	switch ((y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7) {
	case 0:
		return "sunday"
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
		return "monday"
	case:
		return ""
	}
}

calculate_day_of_year :: proc(year, month, day: int) -> int {
	days_before_month := [12]int{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}
	doy := days_before_month[month - 1] + day
	if month > 2 && is_leap_year(year) do doy += 1
	return doy
}
