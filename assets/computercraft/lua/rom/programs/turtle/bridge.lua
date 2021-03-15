-- TODO: settings API?
-- TODO: use modules
local cantMoveMaxWait = 10
local TURTLE_SLOT_COUNT = 16

local function selectNextSlot()
    local slot = turtle.getSelectedSlot()
    local slotToSelect = slot +1
    if slotToSelect > TURTLE_SLOT_COUNT then
        slotToSelect = 1
    end
    turtle.select(slotToSelect)
end

local skipped = {}
local function selectSlotWithBlock(skipCurrent)
    if  (not skipCurrent) and turtle.getItemCount() > 0 then
        return
    end
    if skipCurrent then
        skipped[turtle.getSelectedSlot()] = true
    end
    local startSlot = turtle.getSelectedSlot()
    repeat
        selectNextSlot()
        if turtle.getSelectedSlot() == startSlot then
            print("Out of blocks, add more to continue.")
            os.pullEvent("turtle_inventory")
            skipped = {}
        end
    until (not skipped[turtle.getSelectedSlot()]) and turtle.getItemCount() > 0
end

local function refuel()
    local oldSlelectedSlot = turtle.getSelectedSlot()
    repeat
        selectNextSlot()
        if turtle.getSelectedSlot() == oldSlelectedSlot then
            print("Out of fuel, add more to continue.")
            os.pullEvent("turtle_inventory")
            skipped = {}
        end
    until turtle.refuel()
    turtle.select(oldSlelectedSlot)
end

local function progressivlyLongerWaitFor(callback, maxWaitTime)
    if type(callback) ~= "function" then
        error("bad arg[1], expected function got "..type(callback), 2)
    end
    if maxWaitTime ~= nil and type(maxWaitTime) ~= "number" then
        error("bad arg[2], expected number or nil got "..type(maxWaitTime), 2)
    end

    maxWaitTime = maxWaitTime or math.huge -- math.huge in inf, this might cause issues if we actually wait for ages
    local sleepTime = 0
    while not callback() do
        sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
        os.sleep(sleepTime)
    end
end

local arg = ...
local distance = tonumber(arg)

while true do
    if distance == 0 then
        return
    end
    if distance then
        for i = 1, distance do
            selectSlotWithBlock()
            if not turtle.placeDown() then
                selectSlotWithBlock(true)
            end
            while not turtle.forward() do
                if turtle.getFuelLevel() == 0 then
                    refuel()
                else
                    printError("Can't move, please remove obstuctions to continue.")
                    progressivlyLongerWaitFor(function() return not turtle.detect() end, cantMoveMaxWait)
                end
            end
        end
    end
    local input
    repeat
        print("How far to go? Zero to exit.")
        input = tonumber(read(nil,nil,nil,distance and tostring(distance) or ""))
        if not input then
            print("Please input a whole number (i.e. an interger).")
        end
    until input
    distance = input
end