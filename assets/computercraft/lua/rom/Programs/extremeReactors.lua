
local statusMessageIdentifier = "Main Reactor" -- this is the name that will be sent with status messages when the computer sends them
local reactorName = "BigReactors-Reactor_1"
local turbineName = "BigReactors-Turbine_3" -- edit the config if you know the ideal steam flow rate to skip the lengthy calibration stage
local fuelChestName = "minecraft:chest_49"
local fuelInputHatchName = "bigreactors:tileentityreactoraccessport_2"
local cyaniteChestName = "minecraft:chest_48"
local cyaniteOutputHatchName = "bigreactors:tileentityreactoraccessport_1"
local overrideSide = "top" -- redstone signal disables the computers managing the reactor
local maintenanceSleepTime = 1
local fuelSleepTime = 120
local statusSleetTime = 60


-- CONFIG END
peripheral.find("modem", function(side) rednet.open(side) end)
local REACTOR_PROTOCOL = "Lupus590:extreamReactors/status"

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

local TURBINE_SPEED_TOO_EXSTREAM_THRESHOLD = 100
local TURBINE_SPEED_SLIGHTLY_THRESHOLD = 10
local BEST_TURBINE_SPEED = 1800

local reactor = peripheral.wrap(reactorName) or error("couldn't locate reactor with name/side "..reactorName, 0)
local turbine = reactor.isActivelyCooled() and (peripheral.wrap(turbineName) or error("couldn't locate turbine with name/side "..turbineName, 0)) or nil
local override = false

local configFileName = fs.isReadOnly(fs.getDir(shell.getRunningProgram())) and fs.getName(shell.getRunningProgram())..".config" or shell.getRunningProgram()..".config" -- TODO: avoid startup folder
local config
do
    --
    -- Copyright 2019 Lupus590
    --
    -- Permission is hereby granted, free of charge, to any person obtaining a copy
    -- of this software and associated documentation files (the "Software"), to deal
    -- in the Software without restriction, including without limitation the rights
    -- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    -- copies of the Software, and to permit persons to whom the Software is
    -- furnished to do so, subject to the following conditions: The above copyright
    -- notice and this permission notice shall be included in all copies or
    -- substantial portions of the Software.
    --
    -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    -- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    -- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    -- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    -- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    -- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    -- IN THE SOFTWARE.


    -- heavily inspired by Lyqyd's own config API https://github.com/lyqyd/cc-configuration


    local function tableMerge(...)
        local args = table.pack(...)
        local merged = {}
        for _, arg in ipairs(args) do
            for k, v in pairs(arg) do
            merged[k] = v
            end
        end
        return merged
    end

    local function load(filename, defaultConfig)
        local function unsafeload()
            local file = fs.open(filename, "r")
            local data = textutils.unserialize(file.readAll())
            data = tableMerge(defaultConfig or {}, data)
            file.close()
            return data
        end

        if (not fs.exists(filename)) or fs.isDir(filename) then
            if defaultConfig ~= nil then
                return true, defaultConfig
            else
                return false, "not a file"
            end
        end

        return pcall(unsafeload)
    end

    local function save(filename, data)
        local function unsafeSave()
            local file = fs.open(filename, "w")
            file.write(textutils.serialize(data))
            file.close()
        end

        return pcall(unsafeSave)
    end


    config = {
        load = load,
        save = save,
    }
end
local configOk, configData = config.load(configFileName, {idealFlowRate = turbine and turbine.getFluidFlowRateMaxMax()/2})
if not configOk then
    error("Error loading config: "..configData, 0)
end
local idealFlowRate = configData.idealFlowRate

local lastStatus
local function updateStatus(newStatus, usePrintError)
    if lastStatus ~= newStatus then
        rednet.broadcast({reactorName = statusMessageIdentifier, status = newStatus},REACTOR_PROTOCOL)
        if usePrintError then
            printError(newStatus)
        else
            print(newStatus)
        end
    end
end

local function bufferOpimiser(x)
    -- https://www.desmos.com/calculator
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

local function isTurbineWayTooFast()
    local turbineSpeed = turbine.getRotorSpeed()
    local turbineSpeedDelta = turbineSpeed - BEST_TURBINE_SPEED
    return turbineSpeedDelta > TURBINE_SPEED_TOO_EXSTREAM_THRESHOLD
end

local function isTurbineWayTooSlow()
    local turbineSpeed = turbine.getRotorSpeed()
    local turbineSpeedDelta =  BEST_TURBINE_SPEED - turbineSpeed
    return turbineSpeedDelta > TURBINE_SPEED_TOO_EXSTREAM_THRESHOLD
end

local function isTurbineABitTooFast()
    local turbineSpeed = turbine.getRotorSpeed()
    local turbineSpeedDelta = turbineSpeed - BEST_TURBINE_SPEED
    return turbineSpeedDelta > TURBINE_SPEED_SLIGHTLY_THRESHOLD
end

local function isTurbineABitTooSlow()
    local turbineSpeed = turbine.getRotorSpeed()
    local turbineSpeedDelta =  BEST_TURBINE_SPEED - turbineSpeed
    return turbineSpeedDelta > TURBINE_SPEED_SLIGHTLY_THRESHOLD
end

local oldMode
local function outputMode(mode)
    if mode ~= oldMode then
        updateStatus(mode)
        oldMode = mode
    end
end

local function activelyCooled()
    local energyStored = turbine.getEnergyStored()
    local energyCapacity = turbine.getEnergyCapacity()    
    local energyFilledPercentage = (energyStored / energyCapacity) * 100

    if isTurbineWayTooFast() then
        outputMode("Slowing turbine back down to safe operation.")
        turbine.setFluidFlowRateMax(0)
        turbine.setInductorEngaged(true)
    elseif isTurbineWayTooSlow() then
        outputMode("Turbine is spinning up to optimal speed.")
        turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMaxMax())
        turbine.setInductorEngaged(false)
    else
        if energyFilledPercentage > 75 then
            turbine.setInductorEngaged(false)
            if isTurbineABitTooSlow() then
                outputMode("Topping up speed.")
                local oldSpeed = turbine.getRotorSpeed()
                sleep(1)
                if oldSpeed > turbine.getRotorSpeed() then
                    turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax() + 1)
                end
            else
                outputMode("Idling turbine.")
                turbine.setFluidFlowRateMax(0)
            end
        else
            turbine.setInductorEngaged(true)
            if isTurbineABitTooFast() then
                outputMode("Reducing flow rate.")                
                turbine.setFluidFlowRateMax(idealFlowRate)
                local oldSpeed = turbine.getRotorSpeed()
                sleep(1)
                if oldSpeed < turbine.getRotorSpeed() then
                    local flowRate = turbine.getFluidFlowRate()
                    idealFlowRate = flowRate-1
                    turbine.setFluidFlowRateMax(idealFlowRate)
                end
            elseif isTurbineABitTooSlow() then
                outputMode("Increasing flow rate.")
                local oldSpeed = turbine.getRotorSpeed()
                sleep(1)
                if oldSpeed > turbine.getRotorSpeed() then
                    if turbine.getFluidFlowRate()+1 > turbine.getFluidFlowRateMax() then -- if the actual flow rate is less than the max then changing the max is not going to help
                        idealFlowRate = idealFlowRate+1
                        turbine.setFluidFlowRateMax(idealFlowRate)
                    end
                end
            else
                outputMode("Turbine is operating at optimal speed.")
                turbine.setFluidFlowRateMax(idealFlowRate)
            end
            configData.idealFlowRate = idealFlowRate
            local configSaveOk, err = config.save(configFileName, configData)
            if not configSaveOk then
                error("Error saving config: "..err, 0)
            end
        end
    end

    local steamStored = reactor.getHotFluidAmount()
    local steamCapacity = reactor.getHotFluidAmountMax()
    local steamFilledPercentage = (steamStored / steamCapacity) * 100
    local rodLevelToSet = bufferOpimiser(steamFilledPercentage)
    reactor.setAllControlRodLevels(rodLevelToSet)
end

local function maintanenceLoop()
    while true do
        if not override then
            reactor.setActive(true)

            if reactor.isActivelyCooled() then
                if not turbine then error("turbine not set up, did you change the multiblock?", 0) end
                turbine.setActive(true)
                turbine.setVentAll()
                activelyCooled()
            else
                passivelyCooled()
            end


            sleep(maintenanceSleepTime)
        else
            os.pullEvent("redstone")
        end
    end
end

local function overrideSwitch()
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
    while true do
        if not override then
            cyaniteOutputHatch.pushItems(cyaniteChestName, 1)
            for slot, item in pairs(fuelChest.list()) do
                if FUELS[item.name] then
                    fuelChest.pushItems(fuelInputHatch, slot)
                end
            end

            if next(fuelChest.list()) == nil then
                updateStatus("Fuel buffer empty")
            elseif next(cyaniteOutputHatch.list()) ~= nil then
                updateStatus("Cyanite output full")
            else
                updateStatus("All systems operating")
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

