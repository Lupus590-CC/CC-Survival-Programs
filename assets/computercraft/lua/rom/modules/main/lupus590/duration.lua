--[[
local duration = require("duration")
sleep(1 * duration.minute)
sleep(2 * duration.minutes + 30 * duration.seconds)
]]

local duration= {
	second = 1,
	seconds = 1,
	sec = 1,
	s = 1,
	
	minute = 60,
	minutes = 60,
	min = 60,
	m = 60,
	
	hour = 3600,
	hours = 3600,
	h = 3600,
	
	day = 86400,
	days = 86400,
	d = 86400,
	-- if you need longer than this then define it yourself
	-- I highly doubt that you're going to have a day long timer anyways
}


return duration
