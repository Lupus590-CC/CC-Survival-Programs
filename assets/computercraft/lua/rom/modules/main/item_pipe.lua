-- TODOL arg checking and code cleanup

local function addDestination(pipe, destinationinventory)
    local destination = {_backingTable = {name = destinationinventory}}

    function destination.setFilter(func)
      destination._backingTable.filter = func
      return destination
    end

    function destination.setPriority(priority)
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

  function builtPipe.tick()
    local source = builtPipe._backingTable.source
    local destinations = builtPipe._backingTable.destinations

    for slot, item in pairs(source.list()) do
      local allowOut, outLimit = builtPipe._backingTable.filter(item, slot)
      if allowOut then
        for i = builtPipeDestinations.min, builtPipeDestinations.max do
          if destinations[i] then
            for _, dest in ipairs(destinations[i]) do
              local allowin, inLimit, destSlot = dest.filter(item)
              if allowin then
                source.pushItems(dest.name, slot, (inLimit or outLimit) and math.min(inLimit or math.huge, outLimit or math.huge), destSlot)
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
  local pipe = {_backingTable = {sourceName = sourceInventory, destinations = {}}}

  function pipe.addDestination(destinationinventory)
    return addDestination(pipe, destinationinventory)
  end

  function pipe.removeDestination(destinationinventory)
    pipe._backingTable.destinations[destinationinventory] = nil
    return pipe
  end

  function pipe.setFilter(func)
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

