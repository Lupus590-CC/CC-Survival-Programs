local reactorName = "BigReactors-Reactor_0"
local overrideSide = "top" -- redstone signal disables the computers modifying the reactor
local sleepTime = 1
local rodInsertionAdditive = -0.4

local reactor = peripheral.wrap(reactorName) or error("couldn't locate reactor with name/side "..reactorName)
local override = false

local function maintainenceLoop()
    while true do
        if not override then            
            reactor.setActive(true)
            local energyStored = reactor.getEnergyStored()
            local energyCapacity = reactor.getEnergyCapacity()
            local energyFilledPercentage = (energyStored / energyCapacity) * 100
            local rodLevelToSet = math.max(math.min(energyFilledPercentage + rodInsertionAdditive, 0), 100)
            reactor.setAllControlRodLevels(rodLevelToSet)
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

parallel.waitForAny(overrideSwitch, maintainenceLoop)
