settings.define("lupus590.barrel_filler.input_chest", {
    description = "The peripheral name of the chest to input from.",
    type = "string",
})

settings.define("lupus590.barrel_filler.output_chest", {
    description = "The peripheral name of the chest to output into.",
    type = "string",
})

settings.define("lupus590.barrel_filler.sleep_seconds", {
    description = "True to move unknown items to output, false to keep in input.",
    type = "number",
	default = 1,
})

settings.save()
settings.load()

local SOURCE_NAME = settings.get("lupus590.barrel_filler.input_chest") or error("Input chest is not set, use the set command and set lupus590.barrel_filler.input_chest to a valid networked peripheral.", 0)
local DESTINATION_NAME = settings.get("lupus590.barrel_filler.output_chest") or error("Output chest is not set, use the set command and set lupus590.barrel_filler.output_chest to a valid networked peripheral.", 0)
local SLEEP_SECONDS = settings.get("lupus590.barrel_filler.sleep_seconds")

-- TODO: peripheral.getName
local function addPeripheralName(peripheralName, wrappedPeripheral)
    wrappedPeripheral.PERIPHERAL_NAME = peripheralName
    return wrappedPeripheral
end

local barrelTable = table.pack(peripheral.find("minecraft:block_barrel", addPeripheralName))
local inputChest = peripheral.wrap(SOURCE_NAME)
local outputChest = peripheral.wrap(DESTINATION_NAME)

-- TODO: fluid support
-- TODO: use item and fluid pipe

local function moveToBarrel()
    while true do
        for _, barrel in ipairs(barrelTable) do
            for slot = 1, inputChest.size() do
                while inputChest.pushItems(barrel.PERIPHERAL_NAME, slot) > 0 do end
            end
        end
        sleep(SLEEP_SECONDS)
    end
end

local function moveFromBarrel()
    while true do
        for _, barrel in ipairs(barrelTable) do
            outputChest.pullItems(barrel.PERIPHERAL_NAME, 1)
        end
        sleep(SLEEP_SECONDS)
    end
end

while true do
    parallel.waitForAny(moveToBarrel,moveFromBarrel)
end
