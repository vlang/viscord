module discord
import time

pub fn parse_timestamp(s string) time.Time {
	mut start := s.index('T') or { 0 }
	start++
	end := s.index('+') or { 1 }
	symd := s[0..start]
	ymd :=  symd.split('-')
	year := ymd[0]
	month := ymd[1]
	day := ymd[2]
	shms := s[start..end]
	hms := shms.split(':')
	hour := hms[0]
	minute := hms[1]
	second := hms[2]

	res := time.new_time(time.Time{
		year: ymd[0].int()
		month: ymd[1].int()
		day: ymd[2].int()
		hour: hour.int()
		minute: minute.int()
		second: second.int()
	})
	return res
}