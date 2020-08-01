local reactorName = "BigReactors-Reactor_0"
local overrideSide = "top"
local sleepTime = 1

local reactor = peripheral.wrap(reactorName)
local override = false

local function maintainenceLoop()
    while true do
        if not override then            
            reactor.setActive(true)
            local energyStored = reactor.getEnergyStored()
            local energyCapacity = reactor.getEnergyCapacity()
            local energyFilledPercentage = (energyStored / energyCapacity) * 100
            reactor.setAllControlRodLevels(energyFilledPercentage)
            sleep(sleepTime)
        else
            os.pullEvent("redstone")
        end
    end
end

local function overrideSwitch()
    override = redstone.getInput(overrideSide)
    while true do
        os.pullEvent("redstone")
        override = redstone.getInput(overrideSide)
    end
end

parallel.waitForAny(overrideSwitch, maintainenceLoop)
