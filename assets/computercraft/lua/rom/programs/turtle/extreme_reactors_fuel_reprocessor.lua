if not turtle then
    error("Requires a crafting turtle.", 0)
end

if not turtle.craft then
    error("Crafting upgrade required.", 0)
end

-- TODO: peripheral.getName

settings.define("lupus590.extreme_reactors_fuel_reprocesser.input_side", {
	description = "The side to pull cyanite from. [ top | bottom | front ]",
	type = "string",
})

settings.define("lupus590.extreme_reactors_fuel_reprocesser.output_side", {
	description = "The side to push blutonium into. [ top | bottom | front ]",
	type = "string",
})

settings.define("lupus590.extreme_reactors_fuel_reprocesser.compacting_side", {
	description = "The side to put blutonium ingots when waiting for more to compact them into blocks. Ignored if the compact setting is false. [ top | bottom | front ]",
	type = "string",
})

settings.define("lupus590.extreme_reactors_fuel_reprocesser.compact_blutonium", {
	description = "If true the program will compact blutonium ingots into blocks.",
	type = "boolean",
    default = false,
})

settings.define("lupus590.extreme_reactors_fuel_reprocesser.sleep_time", {
	description = "How long to sleep in seconds when there is no work to do.",
	type = "number",
    default = 120,
})

settings.save()
settings.load()

local inputSide = settings.get("lupus590.extreme_reactors_fuel_reprocesser.input_side")
local outputSide = settings.get("lupus590.extreme_reactors_fuel_reprocesser.output_side")
local compactingSide = settings.get("lupus590.extreme_reactors_fuel_reprocesser.compacting_side")
local compactBlutonium = settings.get("lupus590.extreme_reactors_fuel_reprocesser.compact_blutonium")

inputSide = inputSide and inputSide:lower()
outputSide = outputSide and outputSide:lower()
compactingSide = compactingSide and compactingSide:lower()


if (not inputSide) or (inputSide ~= "top" and inputSide ~= "bottom" and inputSide ~= "front") then
	error("Input side is not set, use the set command and set lupus590.extreme_reactors_fuel_reprocesser.input_side to a valid side.", 0)
end

if (not outputSide) or (outputSide ~= "top" and outputSide ~= "bottom" and outputSide ~= "front") then
	error("output side is not set, use the set command and set lupus590.extreme_reactors_fuel_reprocesser.output_side to a valid side.", 0)
end

if compactBlutonium and ((not compactingSide) or (compactingSide ~= "top" and compactingSide ~= "bottom" and compactingSide ~= "front")) then
	error("Compact blutonium is set to true and compacting side is not set, use the set command and set lupus590.extreme_reactors_fuel_reprocesser.compacting_side to a valid side or set lupus590.extreme_reactors_fuel_reprocesser.compact_blutonium to false.", 0)
end

local drop = {
	top = turtle.dropUp,
	bottom = turtle.dropDown,
	front = turtle.drop,
}

local suck = {
	top = turtle.suckUp,
	bottom = turtle.suckDown,
	front = turtle.suck,
}

local inputSuckFunc = suck[inputSide]
local outputDropFunc = drop[outputSide]
local compactSuckFunc = suck[compactingSide]
local compactDropFunc = drop[compactingSide]
local compactChestName = compactingSide
local inputChestName = inputSide
local sleepTime = settings.get("lupus590.extreme_reactors_fuel_reprocesser.sleep_time")

if not compactBlutonium then
    compactDropFunc = outputDropFunc
end

local reprocessSlots = {
    1,2,3,
    5,  7,
    9,10,11
}
local compactSlots = {
    1,2,3,
    5,6,7,
    9,10,11
}
local cyaniteName = "bigreactors:ingotcyanite"
local blutoniumIngotName = "bigreactors:ingotblutonium"
local blutoniumBlockName = "bigreactors:blockblutonium"
local compactChest = compactBlutonium and peripheral.wrap(compactChestName)
local inputChest = peripheral.wrap(inputChestName)

local function compactInputChest()
    for slot in pairs(inputChest.list()) do
        inputChest.pushItems(inputChestName, slot)
    end
end

local function compactCompactChest()
    for slot in pairs(compactChest.list()) do
        compactChest.pushItems(compactChestName, slot)
    end
end

local function processCyanite()
    compactInputChest()
    -- TODO: pull more from the chest
    local item = inputChest.getItemMeta(1)
    while item and item.count >= #reprocessSlots do            
        local amountToSuck = math.floor(item.count/#reprocessSlots)
        for _, slot in pairs(reprocessSlots) do
            turtle.select(slot)
            inputSuckFunc(math.max(amountToSuck - turtle.getItemCount(), 0))
        end
        turtle.select(16)
        turtle.craft()
        if (not compactDropFunc()) or turtle.getItemCount() > 0  then
            break
        end
        compactInputChest()
        item = inputChest.getItemMeta(1)
    end
end

local function compressBlutonium()
    compactCompactChest()
    -- TODO: pull more from the chest
    local item = compactChest.getItemMeta(1)
    while item and item.count >= #compactSlots do
        local amountToSuck = math.floor(item.count/#compactSlots)
        for _, slot in pairs(compactSlots) do
            turtle.select(slot)
            compactSuckFunc(math.max(amountToSuck - turtle.getItemCount(), 0))
        end
        turtle.select(16)
        turtle.craft()
        while (not outputDropFunc()) or turtle.getItemCount() > 0 do
            sleep(sleepTime)
        end
        compactCompactChest()
        item = compactChest.getItemMeta(1)
    end
end

for slot = 1, 16 do
    turtle.select(slot)
    local item = turtle.getItemDetail()
    if item and item.name ~= cyaniteName then
        if compactBlutonium and item.name == blutoniumIngotName then
            compressBlutonium()
        elseif item.name == blutoniumBlockName or item.name == blutoniumIngotName then
            while not outputDropFunc() do
                sleep(sleepTime)
            end
        else
            error("Unknown item in inventory")
        end
    end
end

while true do
    processCyanite()
    if compactBlutonium then
        compressBlutonium()
    end
    sleep(sleepTime)
end