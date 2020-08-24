local reactorName = "BigReactors-Reactor_1"
local turbineName = "BigReactors-Turbine_3"
local overrideSide = "top" -- redstone signal disables the computers modifying the reactor
local sleepTime = 1

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

local function activelyCooled()
    local energyStored = turbine.getEnergyStored()
    local energyCapacity = turbine.getEnergyCapacity()    
    local energyFilledPercentage = (energyStored / energyCapacity) * 100
    turbine.setInductorEngaged(energyFilledPercentage < 75)

    local turbineSpeed = turbine.getRotorSpeed()
    if turbineSpeed > BEST_TURBINE_SPEED then
        turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()-1)
    else
        turbine.setFluidFlowRateMax(turbine.getFluidFlowRateMax()+1)
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