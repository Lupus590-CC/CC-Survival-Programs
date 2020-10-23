
local TURTLE_SLOT_COUNT = 16

local function selectSlotWithBlock() -- TODO: placeable inteligence
    if turtle.getItemCount() > 0 then
        return
    end
    local startSlot = turtle.getSelectedSlot()
    while turtle.getItemCount() == 0 do
        local slot = turtle.getSelectedSlot()
        local slotToSelect = slot +1
        if slotToSelect > TURTLE_SLOT_COUNT then
            slotToSelect = 1
        end
        turtle.select(slotToSelect)
        if slotToSelect == startSlot then
            print("Out of blocks, add more to continue.")
            os.pullEvent("turtle_inventory")
        end
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
            turtle.placeDown()
            turtle.forward() -- TODO: fuel inteligence
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