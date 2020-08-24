local reactorName = "BigReactors-Reactor_1"
local turbineName = "BigReactors-Turbine_3"
local overrideSide = "top" -- redstone signal disables the computers modifying the reactor
local sleepTime = 1

local TURBINE_SPEED_TOO_EXSTREAM_THRESHOLD = 100
local TURBINE_SPEED_SLIGHTLY_THRESHOLD = 10
local BEST_TURBINE_SPEED = 1800
local reactor = peripheral.wrap(reactorName) or error("couldn't locate reactor with name/side "..reactorName, 0)
local turbine = reactor.isActivelyCooled() and (peripheral.wrap(turbineName) or error("couldn't locate turbine with name/side "..turbineName, 0)) or nil
local override = false

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
        print(mode)
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
                -- TODO: the best flow rate changes depending on the size of the reactor and it's internal stucture
            elseif isTurbineABitTooSlow() then
                outputMode("Increasing flow rate.")
                -- TODO: the best flow rate changes depending on the size of the reactor and it's internal stucture
            else
                outputMode("Turbine is operating at optimal speed.")
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


            sleep(sleepTime)
        else
            os.pullEvent("redstone")
        end
    end
end

local function overrideSwitch()
    local function printControlState()
        if override then
            print("manual override active")
        else
            print("reactor managed by computer")
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

parallel.waitForAny(overrideSwitch, maintanenceLoop)
