local interface = peripheral.wrap("back")
assert(interface, "Must be run on a neural interface with a laser beam and entity sensor.")
assert(interface.fire, "Must be run on a neural interface with a laser beam and entity sensor.")
assert(interface.sense, "Must be run on a neural interface with a laser beam and entity sensor.")

local whiteList = {["Handy__Andy"] = true}
local SLEEP_SECONDS = 0.5

-- this part is adapted from SquidDev's example
local function fireAt(entity)
	local x, y, z = entity.x, entity.y, entity.z
	local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
	local yaw = math.atan2(-x, z)

	interface.fire(math.deg(yaw), math.deg(pitch), 5)
end


while true do
    for _, target in ipairs(interface.sense()) do
        if whiteList[target.name] then
            fireAt(target)
        end
    end
    sleep(SLEEP_SECONDS)
end