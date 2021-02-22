local inputChests = {"minecraft:chest_41", "minecraft:chest_45"}
local refuelChests = {"minecraft:chest_40", "minecraft:chest_46"}
local outputChest = "minecraft:chest_42"
local compactorInputChest = "minecraft:chest_44"
local compactorOutputChest = "minecraft:chest_43"
local proportionOfWoodToSmelt = 1/2
local sleepTime = 120

-- end of config

local electricFurnaceName = "minecraft:gc electric furnace"
local electricFurnaceInputSlot = 2
local electricFurnaceOutputSlots = {3,4}

local function addPeripheralName(peripheralName, wrappedPeripheral)
    wrappedPeripheral.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName
    return wrappedPeripheral
end

local peripheralName = compactorInputChest
compactorInputChest = peripheral.wrap(compactorInputChest)
compactorInputChest.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName
peripheralName = compactorOutputChest
compactorOutputChest = peripheral.wrap(compactorOutputChest)
compactorOutputChest.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName
peripheralName = outputChest
outputChest = peripheral.wrap(outputChest)
outputChest.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName

for k, v in ipairs(inputChests) do
    inputChests[k] = peripheral.wrap(v)
    inputChests[k].PERIPHERAL_NAME = v -- TODO: peripheral.getName
end
for k, v in ipairs(refuelChests) do
    refuelChests[k] = peripheral.wrap(v)
    refuelChests[k].PERIPHERAL_NAME = v -- TODO: peripheral.getName
end

local electricFurnaces = table.pack(peripheral.find(electricFurnaceName, addPeripheralName))


local function splitStacksToTarget(stackSize, destinationCount)
    return math.floor(stackSize/destinationCount)
end

local function compactSlots(chest)
    for slot in pairs(chest.list()) do
        chest.pushItems(chest.PERIPHERAL_NAME, slot) -- TODO: peripheral.getName
    end
end

local function moveFuelToChests()
    compactSlots(compactorOutputChest)
    for slot, item in pairs(compactorOutputChest.list()) do
        if item then
            local limit = splitStacksToTarget(item.count, #refuelChests)
            if limit > 0 then
                for _, refuelChest in ipairs(refuelChests) do
                    compactorOutputChest.pushItems(refuelChest.PERIPHERAL_NAME, slot, limit) -- TODO: peripheral.getName
                end
            end
        end
    end
end

local function moveToSmelters(chest, slot, item)
    local amountToSmelt = math.ceil(item.count * proportionOfWoodToSmelt)
    local limit = math.ceil(amountToSmelt / #electricFurnaces)
    
    for i, furnace in ipairs(electricFurnaces) do
        if i > amountToSmelt then return end
        
        chest.pushItems(furnace.PERIPHERAL_NAME, slot, limit, electricFurnaceInputSlot) -- TODO: peripheral.getName
    end
end

local function emptyInputChests()
    for _, inputChest in ipairs(inputChests) do
        for slot in pairs(inputChest.list()) do
            local item = inputChest.getItemMeta(slot)
            if item then
                if item.name == "minecraft:log" then
                    moveToSmelters(inputChest, slot, item)
                end
                inputChest.pushItems(outputChest.PERIPHERAL_NAME, slot) -- TODO: peripheral.getName
            end
        end
    end
end

local function loadCompactor()
    for _, furnace in ipairs(electricFurnaces) do
        for _, outputSlot in ipairs(electricFurnaceOutputSlots) do
            furnace.pushItems(compactorInputChest.PERIPHERAL_NAME, outputSlot) -- TODO: peripheral.getName
        end
    end
end

while true do
    moveFuelToChests()
    loadCompactor()
    emptyInputChests()
    sleep(sleepTime)
end
