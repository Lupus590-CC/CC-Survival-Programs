local expect = require("cc.expect")


-- TODO: enrich/format
-- TODO: enrich with context
-- TODO: "cc.pretty" things?
-- TODO: meta methods?


local levels = {
	"verbose",
	"debug",
	"information",
	"warning",
	"error",
	"fatal",
}
for k,v in ipairs(levels) do
	levels[v] = k
	levels[v:sub(1,1)] = k
end

local function getLevels()
	local l = {}
	for k,v in pairs(levels) do
		l[v] = k
	end
	return l
end

local sinks ={}

local function registerSink(label, sinkConstuctor)
	expect.expect(1, label, "string")
	expect.expect(2, sinkConstuctor, "function")

	sinks[label] = sinkConstuctor
end

local function createLogger(loggerConfig)
	local logger = {}
	-- logger methods
	for _, v in ipairs(levels) do
		logger[v] = function(input)
			if loggerConfig._minimumLevel > levels[v] then
				return
			end

			local now  = os.epoch("utc")
			local date = os.date("%Y-%m-%d %H:%M:%S", now * 1e-3)
			local milliseconds = ("%.2f"):format(now % 1000 * 1e-3):sub(2)
			local level = levels[v]
			local time = ("%s%s"):format(date, milliseconds)

			for _, sink in pairs(loggerConfig._sinks) do
				sink(level, time, input)
			end
		end
	end

	return logger
end


local function writeTo(loggerConfig)
	local w = {}

	for k, v in pairs(sinks) do
		w[k] = function(...)
			loggerConfig._sinks[k] = v(...)
			return loggerConfig
		end
	end

	return w
end

local function newLoggerConfig()
	local loggerConfig = {
		_sinks = {},
		_minimumLevel = 1,
	}

	loggerConfig.createLogger = function()
		return createLogger(loggerConfig)
	end

	loggerConfig.minimumLevel = function(newLevel)
		expect.expect(1, "newLevel", "number", "string")
		assert(levels[newLevel], "New minimum level is out of range.")
		if type(newLevel) == "string" then
			newLevel = levels[newLevel]
		end
		loggerConfig._minimumLevel = newLevel
        return loggerConfig
	end

	loggerConfig.writeTo = function()
		return writeTo(loggerConfig)
	end

	return loggerConfig
end

registerSink("console", function(terminal)
    if terminal then
        local ok, errOldTerm = pcall(term.redirect, terminal) -- borrow redirect to validate the terminal
        if ok then
            term.redirect(errOldTerm)
        else
            error(errOldTerm, 3)
        end
    end
	terminal = terminal or term.current()
	terminal.setCursorPos(1, 1)
	terminal.setTextColour(colours.white)
	terminal.setBackgroundColour(colours.black)
	terminal.clear()
	terminal.setCursorPos(1, 1)
	local width, height = terminal.getSize()
	terminal.setCursorPos(1, height)

	local strings = require("cc.strings")

	local function log(level, time, rawMessage)
		local formatedMessage = ("[%s %s] %s"):format(level, time, rawMessage) -- TODO: smart colours

		for _, line in ipairs(strings.wrap(formatedMessage, width)) do
			terminal.write(line)
			terminal.scroll(1)
			terminal.setCursorPos(1, height)
		end
	end
	return log
end)

registerSink("filePlainText", function(fileName)
	expect.expect(1, fileName, "string")

	local file, err = fs.open(fileName, "a")
	if not file then
		error(err)
	end

	local function log(level, time, rawMessage)
		local formatedMessage = ("[%s %s] %s"):format(level, time, rawMessage)
		file.writeLine(formatedMessage)
		file.flush()
	end
	return log
end)

registerSink("fileLuaTable", function(fileName) -- We miss the outermost {}'s but the reader can add those
	expect.expect(1, fileName, "string")

	local file, err = fs.open(fileName, "a")
	if not file then
		error(err)
	end

	local function log(level, time, rawMessage)
		local formatedMessage = ([[{level = "%s", time = "%s", message = "%s"},]]):format(level, time, rawMessage)
		file.writeLine(formatedMessage)
		file.flush()
	end
	return log
end)

return {
	getLevels = getLevels,
	registerSink = registerSink,
	newLoggerConfig = newLoggerConfig,
}
