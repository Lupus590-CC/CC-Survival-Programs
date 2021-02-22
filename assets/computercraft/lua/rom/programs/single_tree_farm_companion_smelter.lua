settings.define("lupus590.single_tree_farm_companion_smelter.output_chest", {
    description = "The peripheral name of the output chest.",
    type = "string",
})

settings.define("lupus590.single_tree_farm_companion_smelter.compactor_input_chest", {
    description = "The peripheral name of the chest to put charcoal into for compression into charcoal blocks.",
    type = "string",
})

settings.define("lupus590.single_tree_farm_companion_smelter.compactor_output_chest", {
    description = "The peripheral name of the chest take charcoal blocks from after compression.",
    type = "string",
})

settings.define("lupus590.single_tree_farm_companion_smelter.proportion_of_wood_to_smelt", {
    description = "How much wood to smelt as a proportion. [0 - 1]",
    type = "number",
    default = 0.5,
})

settings.define("lupus590.single_tree_farm_companion_smelter.sleep_time", {
    description = "How long to wait (in seconds) between process cycles.",
    type = "number",
    default = 120,
})

settings.save()
settings.load()

local proportionOfWoodToSmelt = settings.get("lupus590.single_tree_farm_companion_smelter.proportion_of_wood_to_smelt")

if proportionOfWoodToSmelt < 0 or proportionOfWoodToSmelt > 1 then
    error("Proportion of wood to smelt is not valid, it must be between 0 and 1.", 0)
end

local inputChests = {"minecraft:chest_41", "minecraft:chest_45"} -- TODO: find a way to make as a setting
local refuelChests = {"minecraft:chest_40", "minecraft:chest_46"} -- TODO: find a way to make as a setting
local outputChest = settings.get("lupus590.single_tree_farm_companion_smelter.output_chest") or error("Output chest is not set, use the set command and set lupus590.single_tree_farm_companion_smelter.output_chest to a valid side.", 0)
local compactorInputChest = settings.get("lupus590.single_tree_farm_companion_smelter.compactor_input_chest") or error("Compactor input chest is not set, use the set command and set lupus590.single_tree_farm_companion_smelter.compactor_input_chest to a valid side.", 0)
local compactorOutputChest = settings.get("lupus590.single_tree_farm_companion_smelter.compactor_output_chest") or error("Compactor output chest is not set, use the set command and set lupus590.single_tree_farm_companion_smelter.compactor_output_chest to a valid side.", 0)
local sleepTime = settings.get("lupus590.single_tree_farm_companion_smelter.sleep_time")

-- end of config

-- TODO: thermal expansion support?
local electricFurnaceName = "minecraft:gc electric furnace"
local electricFurnaceInputSlot = 2
local electricFurnaceOutputSlots = {3,4}

local function addPeripheralName(peripheralName, wrappedPeripheral)
    wrappedPeripheral.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName
    return wrappedPeripheral
end

local peripheralName = compactorInputChest
compactorInputChest = peripheral.wrap(compactorInputChest) -- TODO: optional?
compactorInputChest.PERIPHERAL_NAME = peripheralName -- TODO: peripheral.getName
peripheralName = compactorOutputChest
compactorOutputChest = peripheral.wrap(compactorOutputChest) -- TODO: optional?
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
