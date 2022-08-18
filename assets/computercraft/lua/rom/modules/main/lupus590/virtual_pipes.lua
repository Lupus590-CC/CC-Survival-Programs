-- TODO: better arg checking (valid peripherals etc.) and code cleanup
local expect = require("cc.expect").expect

local function emptyFilter(_itemOrFluid, _slotOrTank, _peripheralName)
	local _limit, _destinationSlot
	return true, _limit, _destinationSlot
end

local function addFilterAndPrioritySetters(sourceOrDestination)
	function sourceOrDestination.setFilter(func)
        expect(1, func, "function", "nil")
			sourceOrDestination._backingTable.filter = func or emptyFilter
        return sourceOrDestination
    end

    function sourceOrDestination.setPriority(priority)
        expect(1, priority, "number", "nil")
        sourceOrDestination._backingTable.priority = priority
        return sourceOrDestination
    end
end

local function addSource(pipe, sourceinventory)
    local source = {_backingTable = {name = sourceinventory}}

    addFilterAndPrioritySetters(source)

    pipe._backingTable.sources[sourceinventory] = source._backingTable

    return source
end

local function addDestination(pipe, destinationinventory)
    local destination = {_backingTable = {name = destinationinventory}}

    addFilterAndPrioritySetters(destination)

    pipe._backingTable.destinations[destinationinventory] = destination._backingTable

    return destination
end


-- TODO: duplicate code buildSources
local function buildDestinations(pipeBackingTable, builtPipe)
	local builtPipeDestinations = builtPipe._backingTable.destinations
	if (not pipeBackingTable.destinations) or (not next(pipeBackingTable.destinations)) then
		error("No destinations for pipe", 4)
	end
	for _, v in pairs(pipeBackingTable.destinations) do
		local priority = v.priority or 0
		builtPipeDestinations[priority] = builtPipeDestinations[priority] or {n = 0}

		local currentPriorityDestinations = builtPipeDestinations[priority]
		currentPriorityDestinations.n = currentPriorityDestinations.n + 1
		currentPriorityDestinations[currentPriorityDestinations.n] = {name = v.name, filter = v.filter or emptyFilter}

		builtPipeDestinations.min = math.min(builtPipeDestinations.min or 0, priority)
		builtPipeDestinations.max = math.max(builtPipeDestinations.max or 0, priority)
	end
end

local function buildSources(pipeBackingTable, builtPipe)
	local builtPipeSources = builtPipe._backingTable.sources
	if (not pipeBackingTable.sources) or (not next(pipeBackingTable.sources)) then
		error("No Sources for pipe", 4)
	end
	for _, v in pairs(pipeBackingTable.sources) do
		local priority = v.priority or 0
		builtPipeSources[priority] = builtPipeSources[priority] or {n = 0}

		local currentPrioritySources = builtPipeSources[priority]
		currentPrioritySources.n = currentPrioritySources.n + 1
		currentPrioritySources[currentPrioritySources.n] = {name = v.name, filter = v.filter or emptyFilter}

		builtPipeSources.min = math.min(builtPipeSources.min or 0, priority)
		builtPipeSources.max = math.max(builtPipeSources.max or 0, priority)
	end
end

-- TODO: duplicate code buildFluidPipe
local function buildItemPipe(pipe)
	local pipeBackingTable = pipe._backingTable
	--[[ {
		sources = { [name] = { name = ..., filter = ..., prority = ...}},
		filter = ...,
		destinations = { [name] = { name = ..., filter = ..., prority = ...}}
	} ]]

	local builtPipe = {_backingTable = {sources = {}, destinations = {}}}
	--[[ {
		sources = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ...}}},
		destinations = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ...}}}
	} ]]

	buildDestinations(pipeBackingTable, builtPipe)
	buildSources(pipeBackingTable, builtPipe)

	function builtPipe.tick() -- TODO: return true if items moved (client programs can then sleep longer if we didn't move anything)
		local sources = builtPipe._backingTable.sources
		local destinations = builtPipe._backingTable.destinations

		for sourcePriorityLevel = sources.min, sources.max do
			if sources[sourcePriorityLevel] then
				for _, source in ipairs(sources[sourcePriorityLevel]) do
					local ok, list = pcall(peripheral.call, source.name, "list")
					if not ok then
						error("Peripheral `"..source.name.."` disconnected or doesn't exist.", 2)
					end
					for sourceSlot, item in pairs(list) do
						local allowOut, outLimit = source.filter(item, sourceSlot, source.name)
						if allowOut then
							for destinationPriorityLevel = destinations.min, destinations.max do
								if destinations[destinationPriorityLevel] then
									for _, destination in ipairs(destinations[destinationPriorityLevel]) do
										local allowin, inLimit, destSlot = destination.filter(item, nil, destination.name)
										if allowin then
											local limit = (inLimit or outLimit) and math.min(inLimit or math.huge, outLimit or math.huge)
											limit = limit and math.max(limit, 0)

											if (not limit) or limit > 0 then
												local ok, _numItemsMoved = pcall(peripheral.call, source.name, "pushItems", destination.name, sourceSlot, limit, destSlot)
												if not ok then
													error("Peripheral `"..source.name.."` or peripheral `"..destination.name.."` disconnected or doesn't exist.", 2)
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return builtPipe
end

-- TODO: duplicate code newFluidPipe
local function newItemPipe()
	local pipe = {_backingTable = {sources = {}, destinations = {}}}

	function pipe.addSource(sourceInventory)
		expect(1, sourceInventory, "string")
		if pipe._backingTable.sources[sourceInventory] then
			error("Sources can only be in the network once", 2)
		end
		return addSource(pipe, sourceInventory)
	end

	function pipe.removeSource(sourceInventory)
		expect(1, sourceInventory, "string")
		pipe._backingTable.sources[sourceInventory] = nil
		return pipe
	end

	function pipe.addDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		if pipe._backingTable.destinations[destinationinventory] then
			error("Destinations can only be in the network once", 2)
		end
		return addDestination(pipe, destinationinventory)
	end

	function pipe.removeDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		pipe._backingTable.destinations[destinationinventory] = nil
		return pipe
	end

	function pipe.build()
		return buildItemPipe(pipe)
	end

	return pipe
end

local function buildFluidPipe(pipe)
	local pipeBackingTable = pipe._backingTable
	--[[ {
		sources = { [name] = { name = ..., filter = ..., prority = ...}},
		filter = ...,
		destinations = { [name] = { name = ..., filter = ..., prority = ...}}
	} ]]

	local builtPipe = {_backingTable = {sources = {}, destinations = {}}}
	--[[ {
		sources = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ...}}},
		destinations = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ...}}}
	} ]]

	buildDestinations(pipeBackingTable, builtPipe)
	buildSources(pipeBackingTable, builtPipe)

	function builtPipe.tick() -- TODO: return true if items moved (client programs can then sleep longer if we didn't move anything)
		local sources = builtPipe._backingTable.sources
		local destinations = builtPipe._backingTable.destinations

		for sourcePriorityLevel = sources.min, sources.max do
			if sources[sourcePriorityLevel] then
				for _, source in ipairs(sources[sourcePriorityLevel]) do
					local ok, tanks = pcall(peripheral.call, source.name, "list")
					if not ok then
						error("Peripheral `"..source.name.."` disconnected or doesn't exist.", 2)
					end
					for tank, fluid in pairs(tanks) do
						local allowOut, outLimit = source.filter(fluid, tank, source.name)
						if allowOut then
							for destinationPriorityLevel = destinations.min, destinations.max do
								if destinations[destinationPriorityLevel] then
									for _, destination in ipairs(destinations[destinationPriorityLevel]) do
										local allowin, inLimit = destination.filter(fluid, nil, destination.name)
										if allowin then
											local limit = (inLimit or outLimit) and math.min(inLimit or math.huge, outLimit or math.huge)
											limit = limit and math.max(limit, 0)

											if (not limit) or limit > 0 then
												local ok, _quantFluidMoved = pcall(peripheral.call, source.name, "pushFluid", destination.name, limit, fluid.name)
												if not ok then
													error("Peripheral `"..source.name.."` or peripheral `"..destination.name.."` disconnected or doesn't exist.", 2)
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return builtPipe
end

local function newFluidPipe()
	local pipe = {_backingTable = {sources = {}, destinations = {}}}

	function pipe.addSource(sourceInventory)
		expect(1, sourceInventory, "string")
		if pipe._backingTable.sources[sourceInventory] then
			error("Sources can only be in the network once", 2)
		end
		return addSource(pipe, sourceInventory)
	end

	function pipe.removeSource(sourceInventory)
		expect(1, sourceInventory, "string")
		pipe._backingTable.sources[sourceInventory] = nil
		return pipe
	end

	function pipe.addDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		if pipe._backingTable.destinations[destinationinventory] then
			error("Destinations can only be in the network once", 2)
		end
		return addDestination(pipe, destinationinventory)
	end

	function pipe.removeDestination(destinationinventory)
		expect(1, destinationinventory, "string")
		pipe._backingTable.destinations[destinationinventory] = nil
		return pipe
	end

	function pipe.build()
		return buildFluidPipe(pipe)
	end

	return pipe
end

return {
	newItemPipe = newItemPipe,
	newFluidPipe = newFluidPipe,
}
