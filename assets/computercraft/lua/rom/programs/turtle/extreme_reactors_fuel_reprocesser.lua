-- TODO: settings API

-- Turtle Reprocessor side config
local reprocesserInputSuckFunc = turtle and turtle.suck
local reprocesserOutputDropFunc = turtle and turtle.dropUp
local reprocesserCompactSuckFunc = turtle and turtle.suckDown
local reprocesserCompactDropFunc = turtle and turtle.dropDown
local reprocesserCompactChestName = "bottom"
local reprocesserInputChestName = "front"
local reprocesserSleepTime = 120
local compactBlutonium = true

if not compactBlutonium then
    reprocesserCompactDropFunc = reprocesserOutputDropFunc
end


-- cyanite reprocessor
if not turtle then
    error("Requires a crafting turtle.", 0)
end

if not turtle.craft then
    error("Crafting upgrade required.", 0)
end

local reprocessSlots = {
    1,2,3,
    5,  7,
    9,10,11
}
local compactSlots = { -- TODO: make compacting optional, some reactors don't like it
-- ingots might be better for reactor performance anyways
    1,2,3,
    5,6,7,
    9,10,11
}
local cyaniteName = "bigreactors:ingotcyanite"
local bluetoniumIngotName = "bigreactors:ingotblutonium"
local bluetoniumBlockName = "bigreactors:blockblutonium"
local reprocesserCompactChest = peripheral.wrap(reprocesserCompactChestName)
local reprocesserInputChest = peripheral.wrap(reprocesserInputChestName)

local function compactInputChest()        
    for slot in pairs(reprocesserInputChest.list()) do
        reprocesserInputChest.pushItems(reprocesserInputChestName, slot)
    end
end

local function compactCompactChest()
    if compactBlutonium then
        for slot in pairs(reprocesserCompactChest.list()) do
            reprocesserCompactChest.pushItems(reprocesserCompactChestName, slot)
        end
    end
end

local function processCyanite()
    compactInputChest()
    -- TODO: pull more from the chest
    local item = reprocesserInputChest.getItemMeta(1)
    while item and item.count >= #reprocessSlots do            
        local amountToSuck = math.floor(item.count/#reprocessSlots)
        for _, slot in pairs(reprocessSlots) do
            turtle.select(slot)
            reprocesserInputSuckFunc(math.max(amountToSuck - turtle.getItemCount(), 0))
        end
        turtle.select(16)
        turtle.craft()
        if (not reprocesserCompactDropFunc()) or turtle.getItemCount() > 0  then
            break
        end
        compactInputChest()
        item = reprocesserInputChest.getItemMeta(1)
    end
end

local function compactBlutonium()
    compactCompactChest()
    -- TODO: pull more from the chest
    local item = reprocesserCompactChest.getItemMeta(1)
    while item and item.count >= #compactSlots do
        local amountToSuck = math.floor(item.count/#compactSlots)
        for _, slot in pairs(compactSlots) do
            turtle.select(slot)
            reprocesserCompactSuckFunc(math.max(amountToSuck - turtle.getItemCount(), 0))
        end
        turtle.select(16)
        turtle.craft()
        while (not reprocesserOutputDropFunc()) or turtle.getItemCount() > 0 do
            sleep(reprocesserSleepTime)
        end
        compactCompactChest()
        item = reprocesserCompactChest.getItemMeta(1)
    end
end

for slot = 1, 16 do
    turtle.select(slot)
    local item = turtle.getItemDetail()
    if item and item.name ~= cyaniteName then
        if item.name == bluetoniumBlockName then
            while not reprocesserOutputDropFunc() do
                sleep(reprocesserSleepTime)
            end
        elseif item.name == bluetoniumIngotName then
            if not reprocesserCompactDropFunc() then
                compactBlutonium()
            end
        else
            error("Unknown item in inventory")
        end
    end
end

reprocesserSleepTime = 1
while true do
    processCyanite()
    if compactBlutonium then
        compactBlutonium()
    end
    sleep(reprocesserSleepTime)
end