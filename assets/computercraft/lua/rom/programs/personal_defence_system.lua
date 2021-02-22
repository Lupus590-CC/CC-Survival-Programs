-- TODO: settings API?
local whiteList = {["Handy__Andy"] = true}
local POWER = 0.5
local SLEEP_SECONDS = 0.5

local interface = peripheral.wrap("back")
if not (interface and interface.fire and interface.sense) then
    error("Must be run on a neural interface with a laser beam and entity sensor.",0)
end

-- this part is adapted from SquidDev's example
local function fireAt(entity)
	local x, y, z = entity.x, entity.y, entity.z
	local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
	local yaw = math.atan2(-x, z)

	interface.fire(math.deg(yaw), math.deg(pitch), POWER)
end

local function main()
    while true do
        for _, target in ipairs(interface.sense()) do
            if whiteList[target.name] then
                fireAt(target)
            end
        end
        sleep(SLEEP_SECONDS)
    end
end

local function anyKeyExit()
    print("press any key to exit")
    os.pullEvent("key")
end

parallel.waitForAny(main, anyKeyExit)