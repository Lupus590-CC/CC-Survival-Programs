-- status listener

-- TODO: currently is just the reactor status listener, but this will be modified to be more general

local REACTOR_STATUS_PROTOCOL = "Lupus590:extremeReactors/status"
peripheral.find("modem", function(side) rednet.open(side) end)
local statusMessageBackgroundToggle = true

term.setCursorPos(1,1)
term.clear()
term.setCursorPos(1,2)

local function drawClockBar()
    local x, y = term.getCursorPos()
    term.setCursorPos(1,1)
    term.setBackgroundColour(colours.white)
    term.setTextColour(colours.black)
    term.clearLine()
    term.setCursorPos(1,1)
    term.write(textutils.formatTime(os.time("local")))
    term.setCursorPos(x, y)
    term.setTextColour(colours.white)
end

local function clockPrinter()
    while true do
        drawClockBar()
        sleep(15)
    end
end

local function formatMessage(message)
    return textutils.formatTime(os.time("local"))..": "..message.reactorName..": "..message.status
end

local function messagePrinter()
    while true do
        local _, message, protocol = rednet.receive(REACTOR_STATUS_PROTOCOL, 10000000)
        if type(message) == "table" then
            if message.usePrintError then
                printError(formatMessage(message))
            else
                print(formatMessage(message))
            end
            drawClockBar()
            if statusMessageBackgroundToggle then
                term.setBackgroundColour(colours.black)
            else
                term.setBackgroundColour(colours.grey)
            end
            statusMessageBackgroundToggle = not statusMessageBackgroundToggle
        end
    end
end

parallel.waitForAny(messagePrinter, clockPrinter)