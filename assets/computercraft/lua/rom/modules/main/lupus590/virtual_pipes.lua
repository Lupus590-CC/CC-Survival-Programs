-- TODO: code cleanup
-- TODO: use metatable for pipe building and pipes themselves?
-- TODO: can we parallel some of the peripheral calls? client code can paralise the pipes

local expect = require("cc.expect")
local pretty = require("cc.pretty")
local ok, logger = pcall(require, "lupus590.logger")
local log
local nullLogger = setmetatable({}, {_index = function() end})
if ok then
	log = logger.newLoggerConfig()
		.writeTo().console()
		--.writeTo().filePlainText("virtualPipe.plain.log")
		--.writeTo().fileLuaTable("virtualPipe.lua.log")
		.minimumLevel(3)
		.createLogger()

	logger = nil
else
	log = nullLogger
end

local function setLogger(newLogger)
	expect.expect(1, newLogger, "table", "nil")
	if newLogger then
		expect.field(newLogger, "createLogger", "function")
		log = newLogger.createLogger()
	else
		log = nullLogger
	end
end

local function emptyFilter(_itemOrFluid, _slotOrTank, _peripheralName)
	local allowTranfer, _limit, _destinationSlot
	allowTranfer = true
	return allowTranfer, _limit, _destinationSlot
end

local function addFilterAndPrioritySetters(sourceOrDestination)
	if not peripheral.isPresent(sourceOrDestination._backingTable.name) then
		local err = "Peripheral `"..sourceOrDestination._backingTable.name.."` could not be found."
		log.fatal(err)
		error(err, 3)
	end

	function sourceOrDestination.setFilter(func,  withDetail)
        expect.expect(1, func, "function", "nil")
			sourceOrDestination._backingTable.filter = func or emptyFilter
			sourceOrDestination._backingTable.filterWithDetail = not not withDetail -- not not == to boolean
        return sourceOrDestination
    end

    function sourceOrDestination.setPriority(priority)
        expect.expect(1, priority, "number", "nil")
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

local function buildSourceDestination(sourcesDestinations, builtPipeSourceDestination)
	for _, v in pairs(sourcesDestinations) do
		local priority = v.priority or 0
		builtPipeSourceDestination[priority] = builtPipeSourceDestination[priority] or {n = 0}

		local currentPriorityPipes = builtPipeSourceDestination[priority]
		currentPriorityPipes.n = currentPriorityPipes.n + 1
		currentPriorityPipes[currentPriorityPipes.n] = {name = v.name, filter = v.filter or emptyFilter, filterWithDetail = v.filterWithDetail or false}

		builtPipeSourceDestination.min = math.min(builtPipeSourceDestination.min or 0, priority)
		builtPipeSourceDestination.max = math.max(builtPipeSourceDestination.max or 0, priority)
	end
end

local function buildDestinations(pipeBackingTable, builtPipe)
	if (not pipeBackingTable.destinations) or (not next(pipeBackingTable.destinations)) then
		local err = "No destinations for pipe"
		log.fatal(err)
		error(err, 4)
	end
	builtPipe._backingTable = builtPipe._backingTable or {}
	builtPipe._backingTable.destinations = builtPipe._backingTable.destinations or {}
	local builtPipeDestinations = builtPipe._backingTable.destinations

	log.debug("virtual_pipes.lua: vuilding sources")

	buildSourceDestination(pipeBackingTable.destinations, builtPipeDestinations)
end

local function buildSources(pipeBackingTable, builtPipe)
	if (not pipeBackingTable.sources) or (not next(pipeBackingTable.sources)) then
		local err = "No Sources for pipe"
		log.fatal(err)
		error(err, 4)
	end
	builtPipe._backingTable = builtPipe._backingTable or {}
	builtPipe._backingTable.sources = builtPipe._backingTable.sources or {}
	local builtPipeSources = builtPipe._backingTable.sources

	log.debug("virtual_pipes.lua: vuilding sources")

	buildSourceDestination(pipeBackingTable.sources, builtPipeSources)
end

local function tickBuiltPipe(builtPipe, pipeType) -- TODO: return true if items/fluids moved (client programs can then sleep longer if we didn't move anything)
	if pipeType ~= "item" and pipeType ~= "fluid" then
		local err = "Invalid pipe type"
		log.fatal(err)
		error(err, 2)
	end

	local sources = builtPipe._backingTable.sources
	local destinations = builtPipe._backingTable.destinations

	local function processDestinations(itemOrFluid, outLimit, source, slotOrTank)
		for destinationPriorityLevel = destinations.min, destinations.max do
			if destinations[destinationPriorityLevel] then
				log.debug("virtual_pipes.lua: looping destinations at priority = "..destinationPriorityLevel)
				for _, destination in ipairs(destinations[destinationPriorityLevel]) do
					if pipeType == "item" and destination.filterWithDetail and (not source.filterWithDetail) then -- not source.filterWithDetail because we might already have this information
						ok, itemOrFluid = pcall(peripheral.call, source.name, "getItemDetail", slotOrTank) -- list doesn't give everything we sometimes want
						if not ok then
							-- TODO: we wrongly blame this sometimes if the error is terminated or others probably
							local err = listOrTanks
							log.fatal(err)
							error(err, 0)
							err = "Peripheral `"..source.name.."` disconnected or doesn't exist."
							log.fatal(err)
							error(err, 0)
						end
					end
					local allowin, inLimit, destSlot = destination.filter(itemOrFluid, nil, destination.name)
					log.debug(("virtual_pipes.lua: destination filter allowin = %s inLimit = %s destSlot = %s"):format(allowin, inLimit, destSlot))
					if allowin then
						local limit = (inLimit or outLimit) and math.min(inLimit or math.huge, outLimit or math.huge)
						limit = limit and math.max(limit, 0)

						if (not limit) or limit > 0 then
							local ok, _amountMoved
							if pipeType == "item" then
								ok, _amountMoved = pcall(peripheral.call, source.name, "pushItems", destination.name, slotOrTank, limit, destSlot)
							elseif pipeType == "fluid" then
								ok, _amountMoved =  pcall(peripheral.call, source.name, "pushFluid", destination.name, limit, itemOrFluid.name)
							end
							log.debug("virtual_pipes.lua: moved = ".._amountMoved)
							if not ok then
								-- TODO: we wrongly blame this sometimes if the error is terminated or others probably
								local err = _amountMoved
								log.fatal(err)
								error(err, 0)
								err = "Peripheral `"..source.name.."` or peripheral `"..destination.name.."` disconnected or doesn't exist."
								log.fatal(err)
								error(err, 0)
							end
						end
					end
				end
			end
		end
	end

	for sourcePriorityLevel = sources.min, sources.max do
		if sources[sourcePriorityLevel] then
			log.debug("virtual_pipes.lua: looping sources at priority = "..sourcePriorityLevel)
			for _, source in ipairs(sources[sourcePriorityLevel]) do
				log.debug("virtual_pipes.lua: source = "..source.name)
				local ok, listOrTanks
				if pipeType == "item" then
					ok, listOrTanks = pcall(peripheral.call, source.name, "list")
				elseif pipeType == "fluid" then
					ok, listOrTanks = pcall(peripheral.call, source.name, "tanks")
				end
				if not ok then
					-- TODO: we wrongly blame this sometimes if the error is terminated or others probably
					local err = listOrTanks
					log.fatal(err)
					error(err, 0)
					err = "Peripheral `"..source.name.."` disconnected or doesn't exist."
					log.fatal(err)
					error(err, 0)
				end

				log.debug("virtual_pipes.lua: items = "..pretty.render(pretty.pretty(listOrTanks)))
				for slotOrTank, itemOrFluid in pairs(listOrTanks) do
					local itemOrFluid
					if pipeType == "item" and source.filterWithDetail then
						ok, itemOrFluid = pcall(peripheral.call, source.name, "getItemDetail", slotOrTank) -- list doesn't give everything we sometimes want
						if not ok then
							-- TODO: we wrongly blame this sometimes if the error is terminated or others probably
							local err = listOrTanks
							log.fatal(err)
							error(err, 0)
							err = "Peripheral `"..source.name.."` disconnected or doesn't exist."
							log.fatal(err)
							error(err, 0)
						end
					end

					log.debug("virtual_pipes.lua: item/fluid in slot/tank "..slotOrTank)
					local allowOut, outLimit = source.filter(itemOrFluid, slotOrTank, source.name)

					log.debug(("virtual_pipes.lua: source filter allowOut = %s outLimit = %s"):format(allowOut, outLimit))
					if allowOut then
						processDestinations(itemOrFluid, outLimit, source, slotOrTank)
					end
				end
			end
		end
	end
end

local function buildPipe(pipe)
	local pipeBackingTable = pipe._backingTable
	--[[ {
		sources = { [name] = { name = ..., filter = ..., filterWithDetail = bool, prority = ...}},
		destinations = { [name] = { name = ..., filter = ..., filterWithDetail = bool, prority = ...}}
	} ]]

	local builtPipe = {_backingTable = {sources = {}, destinations = {}}}
	--[[ {
		sources = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ..., filterWithDetail = bool}}},
		destinations = { min = 0, max = 0, [priority] = { [n] = { name = ..., filter = ..., filterWithDetail = bool}}}
	} ]]

	buildDestinations(pipeBackingTable, builtPipe)
	buildSources(pipeBackingTable, builtPipe)
	return builtPipe
end

local function buildItemPipe(pipe)
	local builtPipe = buildPipe(pipe)

	function builtPipe.tick()
		return tickBuiltPipe(builtPipe, "item")
	end

	return builtPipe
end

local function buildFluidPipe(pipe)
	local builtPipe = buildPipe(pipe)

	function builtPipe.tick()
		return tickBuiltPipe(builtPipe, "fluid")
	end

	return builtPipe
end

local function newPipe()
	local pipe = {_backingTable = {sources = {}, destinations = {}}}

	-- TODO: verify that sources and destinations are valid inventories/tanks
	function pipe.addSource(sourceInventory)
		expect.expect(1, sourceInventory, "string")
		if pipe._backingTable.sources[sourceInventory] then
			local err = "Sources can only be in the network once"
			log.fatal(err)
			error(err, 2)
		end
		return addSource(pipe, sourceInventory)
	end

	function pipe.addDestination(destinationinventory)
		expect.expect(1, destinationinventory, "string")
		if pipe._backingTable.destinations[destinationinventory] then
			local err = "Destinations can only be in the network once"
			log.fatal(err)
			error(err, 2)
		end
		return addDestination(pipe, destinationinventory)
	end

	function pipe.removeSource(sourceInventory)
		expect.expect(1, sourceInventory, "string")
		pipe._backingTable.sources[sourceInventory] = nil
		return pipe
	end

	function pipe.removeDestination(destinationinventory)
		expect.expect(1, destinationinventory, "string")
		pipe._backingTable.destinations[destinationinventory] = nil
		return pipe
	end

	return pipe
end

local function newItemPipe()
	local pipe = newPipe()

	function pipe.build()
		return buildItemPipe(pipe)
	end

	return pipe
end

local function newFluidPipe()
	local pipe = newPipe()

	function pipe.build()
		return buildFluidPipe(pipe)
	end

	return pipe
end

return {
	newItemPipe = newItemPipe,
	newFluidPipe = newFluidPipe,
	setLogger = setLogger,
}

