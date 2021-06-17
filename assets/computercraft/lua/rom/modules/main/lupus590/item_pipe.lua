-- TODO: better arg checking (valid peripherals etc.) and code cleanup
-- TODO: invert flow option
-- TODO: use assert
local expect = require("cc.expect").expect

local function addDestination(pipe, destinationinventory)
    local destination = {_backingTable = {name = destinationinventory}}

    function destination.setFilter(func)
        expect(1, func, "function")
        destination._backingTable.filter = func
        return destination
    end

    function destination.setPriority(priority)
        expect(1, priority, "number", "nil")
        destination._backingTable.priority = priority
        return destination
    end

    pipe._backingTable.destinations[destinationinventory] = destination._backingTable

    return destination
end

local function emptyFilter()
	return true
end

local function buildPipe(pipe)
	local pipeBackingTable = pipe._backingTable -- { sourceName = ..., filter = ..., destinations = { [name] = { name = ..., filter = ..., prority = ...}}}
	local builtPipe = {_backingTable = {source = peripheral.wrap(pipeBackingTable.sourceName), filter = pipeBackingTable.filter, destinations = {}}}


	builtPipe._backingTable.filter = builtPipe._backingTable.filter or emptyFilter

	local builtPipeDestinations = builtPipe._backingTable.destinations
	for k, v in pairs(pipeBackingTable.destinations) do
		local priority = v.priority or 0
		builtPipeDestinations[priority] = builtPipeDestinations[priority] or {n = 0}

		local currentPriorityDestinations = builtPipeDestinations[priority]
		currentPriorityDestinations.n = currentPriorityDestinations.n + 1
		currentPriorityDestinations[currentPriorityDestinations.n] = {name = v.name, filter = v.filter or emptyFilter}

		builtPipeDestinations.min = builtPipeDestinations.min and math.min(builtPipeDestinations.min, priority) or 0
		builtPipeDestinations.max = builtPipeDestinations.max and math.max(builtPipeDestinations.max, priority) or 0
	end

	function builtPipe.tick() -- TODO: return true if items moved (client programs can then sleep longer if we didn't move anything)
		local source = builtPipe._backingTable.source
		local destinations = builtPipe._backingTable.destinations

		for slot, item in pairs(source.list()) do
			local allowOut, outLimit = builtPipe._backingTable.filter(item, slot) -- TODO: pass the peripheral name too? wrap it?
			if allowOut then
				for i = builtPipeDestinations.min, builtPipeDestinations.max do
					if destinations[i] then
						for _, dest in ipairs(destinations[i]) do
							local allowin, inLimit, destSlot = dest.filter(item) -- TODO: pass the peripheral name too? wrap it?
							if allowin then
								local limit = (inLimit or outLimit) and math.min(inLimit or math.huge, outLimit or math.huge)
								limit = limit and math.max(limit, 0)
								source.pushItems(dest.name, slot, limit, destSlot)
							end
						end
					end
				end
			end
		end
	end

	return builtPipe
end

local function newPipe(sourceInventory)
	expect(1, sourceInventory, "string")
	local pipe = {_backingTable = {sourceName = sourceInventory, destinations = {}}}

	function pipe.addDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		return addDestination(pipe, destinationinventory)
	end

	function pipe.removeDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		pipe._backingTable.destinations[destinationinventory] = nil
		return pipe
	end

	function pipe.setFilter(func)
		expect(1, func, "function", "nil")
		pipe._backingTable.filter = func
		return pipe
	end

	function pipe.build()
		return buildPipe(pipe)
	end

	return pipe
end




return {
	newPipe = newPipe,
}

