-- TODO: settings API

--config
local SOURCE_NAME = "minecraft:chest_38"
local DESTINATION_NAME = "minecraft:chest_39"
local SLEEP_SECONDS = 1

--code
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
