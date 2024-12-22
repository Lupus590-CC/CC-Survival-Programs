settings.define("lupus590.extreme_reactors.reactor_name", {
    description = "The peripheral name of the reactor.",
    type = "string",
})

settings.define("lupus590.extreme_reactors.override_side", {
    description = "The side to accept redstone signals for putting the reactor into manual mode. [ top | bottom | left | right | front | back | no_manual ]",
    type = "string",
})

settings.define("lupus590.extreme_reactors.maintenance_sleep_time", {
    description = "How long to wait between reactor checks.",
    type = "number",
	default = 1,
})

settings.define("lupus590.extreme_reactors.fuel_sleep_time", {
    description = "How long to wait between refuel cycles.",
    type = "number",
	default = 120,
})

settings.define("lupus590.extreme_reactors.status_sleep_time", {
    description = "How long to wait before sending a status message that's the same as the immediate previous message.",
    type = "number",
	default = 60,
})

settings.save()
settings.load()

-- REQUIRED CONFIG
local reactorName = settings.get("lupus590.extreme_reactors.reactor_name") or error("Reactor name is not set, use the set command and set lupus590.extreme_reactors.reactor_name to a valid networked peripheral.", 0)
local overrideSide = settings.get("lupus590.extreme_reactors.override_side")
local maintenanceSleepTime = settings.get("lupus590.extreme_reactors.maintenance_sleep_time")
local fuelSleepTime = settings.get("lupus590.extreme_reactors.fuel_sleep_time")
local statusSleepTime = settings.get("lupus590.extreme_reactors.status_sleep_time")
local statusMessageIdentifier = "Main Reactor" -- this is the name that will be sent with status messages when the computer sends them

local fuelChestName = "minecraft:chest_63"
local fuelInputHatchName = "bigreactors:tileentityreactoraccessport_3" -- TODO: have input and output port be the same
local cyaniteChestName = "minecraft:chest_48"
local cyaniteOutputHatchName = "bigreactors:tileentityreactoraccessport_1"

-- TODO: reactor temperature control, reactor get's less efficient if it's too hot. want to maximise fuel reactivity while maintaining required output
-- TODO: better control rod usage, should help with temp control
-- TODO: multiple reactor support?

overrideSide = overrideSide and overrideSide:lower()
if not (overrideSide == "top" or overrideSide == "bottom" or overrideSide == "back" or overrideSide == "front" or overrideSide == "left" or overrideSide == "right" or overrideSide == "no_manual") then
    error("Override side is not set or is not valid, use the set command and set lupus590.extreme_reactors.override_side to a valid side.", 0)
end

-- CONFIG END
peripheral.find("modem", function(side) rednet.open(side) end)
local REACTOR_STATUS_PROTOCOL = "Lupus590:extremeReactors/status"


local FUELS = {
    ["bigreactors:ingotblutonium"] = "Bluetonium ingots",
    ["bigreactors:blockblutonium"] = "Bluetonium blocks",
    ["bigreactors:ingotyellorium"] = "Yellorium ingots",
    ["bigreactors:blockyellorium"] = "Yellorium blocks",
}

local fuelChest = peripheral.wrap(fuelChestName)
local fuelInputHatch = peripheral.wrap(fuelInputHatchName)
local cyaniteChest = peripheral.wrap(cyaniteChestName)
local cyaniteOutputHatch = peripheral.wrap(cyaniteOutputHatchName)

local reactor = peripheral.wrap(reactorName) or error("couldn't locate reactor with name/side "..reactorName, 0)
local override = false

local lastStatusTime = -statusSleepTime
local lastStatus
local statusMessageBackgroundToggle = true

local function updateStatus(newStatus, usePrintError) -- TODO: use cc.strings
    if lastStatus ~= newStatus or lastStatusTime + statusSleepTime < os.clock() then
        lastStatus = newStatus
        lastStatusTime = os.clock()
        rednet.broadcast({reactorName = statusMessageIdentifier, status = newStatus, usePrintError = usePrintError},REACTOR_STATUS_PROTOCOL)
        if usePrintError then
            printError(newStatus)
        else
            print(newStatus)
        end
        if statusMessageBackgroundToggle then
            term.setBackgroundColour(colours.black)
        else
            term.setBackgroundColour(colours.grey)
        end
        statusMessageBackgroundToggle = not statusMessageBackgroundToggle
    end
end

local function bufferOpimiser(x)
    -- https://www.desmos.com/calculator
	-- y=100\cdot e^{\frac{-\left(x-100\right)^{2}}{10}}
    x = math.min(math.max(x, 0), 100)
    local fraction = -(((x-100)*(x-100))/(10))
    local y = 100 * math.exp(fraction)
    return y
end

local function passivelyCooled()
    local energyStored = reactor.getEnergyStored()
    local energyCapacity = reactor.getEnergyCapacity()
    local energyFilledPercentage = (energyStored / energyCapacity) * 100
    local rodLevelToSet = bufferOpimiser(energyFilledPercentage)
    reactor.setAllControlRodLevels(rodLevelToSet)
end

local function activelyCooled()

    local steamStored = reactor.getHotFluidAmount()
    local steamCapacity = reactor.getHotFluidAmountMax()
    local steamFilledPercentage = (steamStored / steamCapacity) * 100
    -- local rodLevelToSet = bufferOpimiser(steamFilledPercentage)
    reactor.setAllControlRodLevels(steamFilledPercentage)
end

local lastPowerAmount
local function reportPowerGenerated()
    local currentPower = reactor.getEnergyStored()
    if lastPowerAmount then
        local deltaPower = currentPower-lastPowerAmount -- positive means increasing
        if (deltaPower > 0 and currentPower > 0) or reactor.getControlRodLevel(0) > 0 then
            updateStatus("Stable power generation")
        else
            updateStatus("WARNING! Power demand excedes max generation")
        end
    end
    lastPowerAmount = currentPower
end

local lastSteamAmount
local function reportSteamGenerated()
    local currentSteam = reactor.getEnergyStored()
    if lastSteamAmount then
        local deltaSteam = currentSteam-lastSteamAmount -- positive means increasing
        if (deltaSteam > 0 and currentSteam > 0) or reactor.getControlRodLevel(0) > 0 then
            updateStatus("Stable steam generation")
        else
            updateStatus("WARNING! Steam demand excedes max generation")
        end
    end
    lastSteamAmount = currentSteam
end

local function maintanenceLoop()
    while true do
        if not override then
            reactor.setActive(true)

            if reactor.isActivelyCooled() then
                activelyCooled()

                reportSteamGenerated()
            else
                passivelyCooled()

                reportPowerGenerated()
            end


            sleep(maintenanceSleepTime)
        else
            os.pullEvent("redstone")
        end
    end
end

local function overrideSwitch()
	if overrideSide == "no_manual" then
		updateStatus("No override side set, reactor will always be managed by the computer")
		os.pullEvent("Lupus590.NonExistingEvent")
	end
    local function printControlState()
        if override then
            updateStatus("Manual override active")

        else
            updateStatus("Reactor managed by computer")
        end
    end

    override = redstone.getInput(overrideSide)
    printControlState()
    while true do
        os.pullEvent("redstone")
        override = redstone.getInput(overrideSide)
        printControlState()
    end
end

local function fuelSystem()
    if (not cyaniteOutputHatch) or (not fuelInputHatch) or (not fuelChest) or (not cyaniteChest) then
        updateStatus("WARNING! Fuel system offline, chests or hatches not found.")
        os.pullEvent("Lupus590:FakeEvent")
    end
    while true do
        if not override then
            cyaniteOutputHatch.pushItems(cyaniteChestName, 1)
            for slot, item in pairs(fuelChest.list()) do
                if FUELS[item.name] then
                    fuelChest.pushItems(fuelInputHatchName, slot)
                end
            end

            if next(fuelChest.list()) == nil then
                updateStatus("Fuel buffer empty")
            elseif next(cyaniteOutputHatch.list()) ~= nil then
                updateStatus("Cyanite output full")
            else
                updateStatus("Fuel system operating normally")
            end

            sleep(fuelSleepTime)
        else
            os.pullEvent("redstone")
        end
    end
end

local ok, err = pcall(parallel.waitForAny, overrideSwitch, maintanenceLoop, fuelSystem)
if not ok then
    updateStatus("ERROR!\n"..err, true)
end

