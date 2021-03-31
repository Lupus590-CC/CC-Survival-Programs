settings.define("lupus590.extreme_reactors_turbine.override_side", {
    description = "The side to accept redstone signals for putting the turbine into manual mode. [ top | bottom | left | right | front | back ]",
    type = "string",
})

settings.define("lupus590.extreme_reactors_turbine.maintenance_sleep_time", {
    description = "How long to wait between turbine checks.",
    type = "number",
	default = 1,
})

settings.define("lupus590.extreme_reactors_turbine.status_sleep_time", {
    description = "How long to wait before sending a status message that's the same as the immediate previous message.",
    type = "number",
	default = 60,
})

settings.define("lupus590.extreme_reactors_turbine.turbine_name", {
    description = "The side to accept redstone signals for putting the turbine into manual mode. [ top | bottom | left | right | front | back ]",
    type = "string",
})

settings.define("lupus590.extreme_reactors_turbine.turbine_target_energy_percentage", {
    description = "What percentage of the energy buffer needs to be full before the turbine will go into an idle mode. The turbine can be slow to react, setting this higher means that you have a bigger buffer but are more likly to waste power. However, if it's too low you have the risk of running out of power.",
    type = "number",
	default = 95,
})

settings.save()
settings.load()

local overrideSide = settings.get("lupus590.extreme_reactors_turbine.override_side")
local maintenanceSleepTime = settings.get("lupus590.extreme_reactors_turbine.maintenance_sleep_time")
local statusSleepTime = settings.get("lupus590.extreme_reactors_turbine.status_sleep_time")
local statusMessageIdentifier = "Main Reactor Turbine" -- this is the name that will be sent with status messages when the computer sends them

-- If you don't have these peripherals then you can ignore the config entry, the computer will try to continue without valid values
local turbineName = settings.get("lupus590.extreme_reactors_turbine.turbine_name")
local turbineTargetEnergyPercentage = settings.get("lupus590.extreme_reactors_turbine.turbine_target_energy_percentage") -- the turbine can be slow to react, setting this higher means that you have a bigger buffer but are more likly to waste power. However, if it's too low you have the risk of running out of power.

-- TODO: multiple turbine support?

-- TODO: something about rotor efficiency

overrideSide = overrideSide and overrideSide:lower()
if not (overrideSide == "top" or overrideSide == "bottom" or overrideSide == "back" or overrideSide == "front" or overrideSide == "left" or overrideSide == "right") then
    error("Override side is not set or is not valid, use the set command and set lupus590.extreme_reactors_turbine.override_side to a valid side.", 0)
end


-- CONFIG END
peripheral.find("modem", function(side) rednet.open(side) end)
local REACTOR_STATUS_PROTOCOL = "Lupus590:extremeReactors/status"

local TURBINE_SPEED_TOO_EXSTREAM_THRESHOLD = 100
local TURBINE_SPEED_SLIGHTLY_THRESHOLD = 10
local BEST_TURBINE_SPEED = 1800

local turbine = peripheral.wrap(turbineName) or error("couldn't locate turbine with name/side "..turbineName, 0)
local override = false

-- TODO: use setting API? we save one thing
local config -- TODO: require
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

    local function getConfigLocation(fileName) -- tries to place config next to program, avoiding read only locations and the startup directory and going for root instead
        local programDir = fs.getDir(shell.getRunningProgram())
        if fs.isReadOnly(programDir) or programDir:lower() == "startup" then
            return fileName
        else
            return fs.combine(fs.getDir(shell.getRunningProgram()), fileName)
        end
    end


    config = {
        load = load,
        save = save,
        getConfigLocation = getConfigLocation
    }
end

local configFileName = config.getConfigLocation(fs.getName(shell.getRunningProgram()..".config"))

local configOk, configData = config.load(configFileName, {idealFlowRate = turbine and turbine.getFluidFlowRateMaxMax()/2})
if not configOk then
    error("Error loading config: "..configData, 0)
end
local idealFlowRate = configData.idealFlowRate

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
    x = math.min(math.max(x, 0), 100)
    local fraction = -(((x-100)*(x-100))/(10))
    local y = 100 * math.exp(fraction)
    return y
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
        if energyFilledPercentage > turbineTargetEnergyPercentage then
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
end

local lastPowerAmount
local function reportPowerGenerated(device)
    local currentPower = device.getEnergyStored()
    if lastPowerAmount then
        local deltaPower = currentPower-lastPowerAmount -- positive means increasing
        if turbine.getFluidFlowRate() < turbine.getFluidFlowRateMax() then
            updateStatus("Losing power, turbine needs more steam - reactor might not be keeping up")
        elseif (deltaPower > 0 and currentPower > 0) or (turbine.getInductorEngaged() == false and turbine.getFluidFlowRate() == 0) then
            updateStatus("Stable power generation")
        elseif turbine.getInductorEngaged() == false and turbine.getFluidFlowRate() > 0 then
            updateStatus("Losing power, turbine is spinning up")
        else
            updateStatus("WARNING! Power demand exceedes max generation")
        end
        
    end
    lastPowerAmount = currentPower
end

local function maintanenceLoop()
    while true do
        if not override then
            turbine.setActive(true)
            turbine.setVentOverflow()
            activelyCooled()
            
            reportPowerGenerated(turbine)


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
            updateStatus("Turbine managed by computer")
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

local ok, err = pcall(parallel.waitForAny, overrideSwitch, maintanenceLoop)
if not ok then
    updateStatus("ERROR!\n"..err, true)
end

