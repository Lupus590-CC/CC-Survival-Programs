local INPUT_CHEST_NAME = "minecraft:chest_21"
local OUTPUT_CHEST_NAME = "minecraft:chest_22"
local PASS_THROUGH_JUNK = false -- true to move unknown items to output, false to keep in input

-- TODO: remove unused API functions

local argValidationUtils
do

  local function argChecker(position, value, validTypesList, level)
    -- check our own args first, sadly we can't use ourself for this
    if type(position) ~= "number" then
      error("argChecker: arg[1] expected number got "..type(position),2)
    end
    -- value could be anything, it's what the caller wants us to check for them
    if type(validTypesList) ~= "table" then
      error("argChecker: arg[3] expected table got "..type(validTypesList),2)
    end
    if not validTypesList[1] then
      error("argChecker: arg[3] table must contain at least one element",2)
    end
    for k, v in ipairs(validTypesList) do
      if type(v) ~= "string" then
        error("argChecker: arg[3]["..tostring(k).."] expected string got "..type(v),2)
      end
    end
    if type(level) ~= "nil" and type(level) ~= "number" then
      error("argChecker: arg[4] expected number or nil got "..type(level),2)
    end
    level = level and level + 1 or 3
  
    -- check the client's stuff
    for k, v in ipairs(validTypesList) do
      if type(value) == v then
        return
      end
    end
  
    local expectedTypes
    if #validTypesList == 1 then
        expectedTypes = validTypesList[1]
    else
        expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList - 1) .. " or " .. validTypesList[#validTypesList]
    end
  
    error("arg["..tostring(position).."] expected "..expectedTypes
    .." got "..type(value), level)
  end

  local function tableChecker(positionInfo, tableToCheck, templateTable, rejectExtention, level)
    argChecker(1, positionInfo, {"string"})
    argChecker(2, tableToCheck, {"table"})
    argChecker(3, templateTable, {"table"})
    argChecker(4, rejectExtention, {"boolean", "nil"})
    argChecker(5, level, {"number", "nil"})
  
    level = level and level + 1 or 3
  
    local hasElements = false
    for k, v in pairs(templateTable) do
      hasElements = true
      if type(v) ~= "table" then
        error("arg[3]["..tostring(k).."] expected table got "..type(v),2)
      end
      for k2, v2 in pairs(v) do
        if type(v2) ~= "string" then
           error("arg[3]["..tostring(k).."]["..tostring(k2).."] expected string  got "..type(v2),2)
        end
      end
    end
    if not hasElements then
      error("arg[3] table must contain at least one element",2)
    end
  
  
    local function elementIsValid(element, validTypesList)
      for k, v in ipairs(validTypesList) do
        if type(element) == v then
          return true
        end
      end
      return false
    end
  
    -- check the client's stuff
    for key, value in pairs(tableToCheck) do
      if (rejectExtention) and (not templateTable[key]) then
        error(positionInfo.." table has invalid key "..tostring(key), level)
      end
  
      local validTypesList = templateTable[key]
      if validTypesList and not elementIsValid(value, validTypesList) then
        local expectedTypes
        if #validTypesList == 1 then
            expectedTypes = validTypesList[1]
        else
            expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList  - 1) .. " or " .. validTypesList[#validTypesList]
        end
  
        error(positionInfo.."["..tostring(key).."] expected "..expectedTypes
        .." got "..type(value), level)
      end
    end

    local function acceptsNil(template)
      for _, v in ipairs(template) do
        if v == "nil" then
          return true
        end
      end
      return false
    end
  
    for k in pairs(templateTable) do
      if (not acceptsNil(templateTable[k])) and tableToCheck[k] == nil then
        error(positionInfo.." table is missing key: "..tostring(k),  level)
      end
    end
  end

  local function numberRangeChecker(argPosition, value, lowerBound, upperBound, level)
    argChecker(1, argPosition, {"number"})
    argChecker(2, value, {"number"})
    argChecker(3, lowerBound, {"number", "nil"})
    argChecker(4, upperBound, {"number", "nil"})
    argChecker(5, level, {"number", "nil"})
    level = level and level +1 or 3
  
    if lowerBound > upperBound then
      local temp = upperBound
      upperBound = lowerBound
      lowerBound = temp
    end
  
    if value < lowerBound or value > upperBound then
      error("arg["..argPosition.."] must be between "..lowerBound.." and "..upperBound,level)
    end
  end

  local function itemIdChecker(argPosition, itemIdArg)
    argChecker(1, argPosition, {"number"}, 2)
  
    argChecker(argPosition, itemIdArg, {"table"}, 3)
    --argChecker(position, value, validTypesList, level)
    tableChecker("arg["..argPosition.."]", itemIdArg, {name = {"string"}, damage = {"number", "nil"}}, nil, 3)
  end

  argValidationUtils = {
    argChecker = argChecker,
    tableChecker = tableChecker,
    numberRangeChecker = numberRangeChecker,
    itemIdChecker = itemIdChecker
  }
end

local itemUtils
do

  local function itemEqualityComparer(itemId1, itemId2)
    argValidationUtils.argChecker(1, itemId1, {"table", "nil"})
    argValidationUtils.argChecker(2, itemId2, {"table", "nil"})
    if itemId1 then
      argValidationUtils.itemIdChecker(1, itemId1)
    else
      itemId1 = {}
    end
    if itemId2 then
      argValidationUtils.itemIdChecker(2, itemId2)
    else
      itemId1 = {}
    end
    if itemId1 == itemId2 or (itemId1.name == itemId2.name and (itemId1.damage and itemId2.damage and itemId1.damage == itemId2.damage or true)) then
      return true
    end
    return false
  end

  local function itemEqualityComparerWithCount(itemId1, itemId2)
    argValidationUtils.argChecker(1, itemId1, {"table", "nil"})
    argValidationUtils.argChecker(2, itemId2, {"table", "nil"})

    local function countCheck(pos, item)
      argValidationUtils.tableChecker("arg["..pos.."]", item, {count = {"number"}})
    end

    if itemId1 then
      argValidationUtils.itemIdChecker(1, itemId1)
      countCheck(1, itemId1)
    end
    if itemId2 then
      argValidationUtils.itemIdChecker(2, itemId2)
      countCheck(2, itemId2)
    end

    if itemId1 == itemId2 or ((type(itemId1) == "table" and itemId1.count) == (type(itemId1) == "table" and itemId2.count) and itemEqualityComparer(itemId1, itemId2)) then
      return true
    end
    return false
  end

  itemUtils = {
    itemEqualityComparer = itemEqualityComparer,
    itemEqualityComparerWithCount = itemEqualityComparerWithCount,
  }
end

local invUtils
do
  --wraps inventories and adds uility methods for them

  local function inject(inventory)
    argValidationUtils.argChecker(1, inventory, {"table", "string"})
    if type(inventory) == "string" then
      local peripheralName = inventory
      if not peripheral.isPresent(peripheralName) then
        error("Could not wrap peripheral with name "..peripheralName, 1)
      end
      inventory = peripheral.wrap(peripheralName)
      inventory.PERIPHERAL_NAME = peripheralName
      argValidationUtils.tableChecker("peripheral.wrap(arg[1])", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})
    else
      argValidationUtils.tableChecker("arg[1]", inventory, {size = {"function"}, getItem = {"function"}, list = {"function"}})
    end

    inventory.eachSlot = function()
      local currentSlot = 0
      local invSize = inventory.size()
      local function iterator()
        currentSlot = currentSlot+1
        if currentSlot > invSize then
          return
        end
        if inventory.allowChangeOfSelectedSlot and inventory.IS_THIS_TURTLE_INV then
          turtle.select(currentSlot)
        end
        return currentSlot, inventory.getItemMeta(currentSlot)
      end
      return iterator
    end

    inventory.eachSlotSkippingEmpty = function()
      local eachSlotIterator = inventory.eachSlot()
      local function iterator()
        local slot, item
        repeat
          slot, item = eachSlotIterator()
          if slot == nil then
            return
          end
        until item
        return slot, item
      end
      return iterator
    end

    inventory.eachSlotWithItem = function(targetItem)
      argValidationUtils.argChecker(1, targetItem, {"table", "nil"})
      if not targetItem then
        return inventory.eachSlotSkippingEmpty()
      end
      argValidationUtils.itemIdChecker(1, targetItem)
      local eachSlotSkippingEmptyIterator = inventory.eachSlotSkippingEmpty()
      local function iterator()
        local slot, item
        repeat
          slot, item = eachSlotSkippingEmptyIterator()
          if slot == nil then
            return
          end
        until itemUtils.itemEqualityComparer(item, targetItem)
        return slot, item
      end
      return iterator
    end

    inventory.findItemById = function(item)
      argValidationUtils.itemIdChecker(1, item)
      local iterator = inventory.eachSlotWithItem(item)
      local slot, item = iterator()
      return slot, item
    end

    inventory.slotIsEmpty = function(slot)
      if inventory.IS_THIS_TURTLE_INV then
        slot = slot or turtle.getSelectedSlot()
      end
      argValidationUtils.argChecker(1, slot, {"number"})
      local item = inventory.getItemMeta(slot)
      if not item then
        return true
      end
      return false
    end

    inventory.eachEmptySlot = function()
      local eachSlotIterator = inventory.eachSlot()
      local function iterator()
        local slot, item
        repeat
          slot, item = eachSlotIterator()
          if slot == nil then
            return
          end
        until not item
        return slot
      end
      return iterator
    end

    inventory.findEmptySlot = function()
      local iterator = inventory.eachEmptySlot()
      local slot = iterator()
      return slot
    end

    inventory.getTotalItemCount = function(itemToCount)
      argValidationUtils.argChecker(1, itemToCount, {"table", "nil"})
      if itemToCount then
        argValidationUtils.itemIdChecker(1, itemToCount)
      end
      local total = 0
      for _, item in inventory.eachSlotWithItem(itemToCount) do
        total = total + item.getMetadata().count
      end
      return total
    end

    inventory.getFreeSpaceCount = function()
      local total = 0
      for _ in inventory.eachEmptySlot() do
        total = total + 1
      end
      return total
    end

    inventory.compactItemStacks = function()
      if inventory.IS_THIS_TURTLE_INV then
        for sourceSlot in inventory.eachSlotWithItem() do
          if inventory.allowChangeOfSelectedSlot then
            turtle.select(sourceSlot)
          end
          for destinationSlot = 1, sourceSlot do
            if turtle.getItemCount() > 0 then
              turtle.transferTo(destinationSlot)
            end
          end
        end
      else
        argValidationUtils.tableChecker("self", inventory, {list = {"function"}, PERIPHERAL_NAME = {"string"}, pushItems = {"function"}})
        for slot in pairs(inventory.list()) do
          inventory.pushItems(inventory.PERIPHERAL_NAME, slot)
        end
      end
    end

  -- parrallel methods
    -- if the inv is a turtle one then we fall back to using the sequential methods


    inventory.eachSlotParrallel = function(callback)
      argValidationUtils.argChecker(1, callback, {"function"})
      -- turtles can't safely parrallel
      if inventory.IS_THIS_TURTLE_INV then
        for slot, item in inventory.eachSlot() do
          callback(slot, item)
        end
        return
      end

      local tasks = {}
      local itemMetaOrGetitemFunc = inventory.getItemMeta or inventory.getItemInfo
      for i = 1, inventory.size() do
        tasks[i] = function()
          local slot = i
          callback(slot, itemMetaOrGetitemFunc(slot))
        end
      end

      parallel.waitForAll(table.unpack(tasks, 1, inventory.size()))
    end

    inventory.eachSlotSkippingEmptyParrallel = function(callback)
      argValidationUtils.argChecker(1, callback, {"function"})
      if inventory.IS_THIS_TURTLE_INV then
        for slot, item in inventory.eachSlotSkippingEmpty() do
          callback(slot, item)
        end
        return
      end

      inventory.eachSlotParrallel(function(slot, item)
        if item then
          callback(slot, item)
        end
      end)
    end

    inventory.eachSlotWithItemParrallel = function(targetItem, callback)
      argValidationUtils.argChecker(1, targetItem, {"table", "nil"})
      argValidationUtils.argChecker(2, callback, {"function"})
      if not targetItem then
        return inventory.eachSlotSkippingEmptyParrallel(callback)
      end
      argValidationUtils.itemIdChecker(1, targetItem)

      if inventory.IS_THIS_TURTLE_INV then
        for slot, item in inventory.eachSlotWithItem(targetItem) do
          callback(slot, item)
        end
        return
      end

      inventory.eachSlotParrallel(function(slot, item)
        if itemUtils.itemEqualityComparer(item, targetItem) then
          callback(slot, item)
        end
      end)
    end

    inventory.findItemByIdParrallel = function(item)
      argValidationUtils.itemIdChecker(1, item)
      if inventory.IS_THIS_TURTLE_INV then
        return inventory.findItemById(item)
      end

      local slotfound, itemFound
      inventory.eachSlotWithItemParrallel(item, function(slot, item) -- could be faster with parallel.waitForAny
        slotfound = slot
        itemFound = itemFound
      end)
      return slotfound, itemFound
    end

    inventory.eachEmptySlotParrallel = function(callback)
      argValidationUtils.argChecker(1, callback, {"function"})
      if inventory.IS_THIS_TURTLE_INV then
        for slot, item in inventory.eachEmptySlot() do
          callback(slot, item)
        end
        return
      end

      inventory.eachSlotParrallel(function(slot, item)
        if not item then
          callback(slot)
        end
      end)
    end

    inventory.getTotalItemCountParrallel = function(itemToCount)
      argValidationUtils.argChecker(1, itemToCount, {"table", "nil"})
      if itemToCount then
        argValidationUtils.itemIdChecker(1, itemToCount)
      end
      local total = 0
      inventory.eachSlotWithItemParrallel(itemToCount, function(_, item)
        total = total + item.count
      end)
      return total
    end

    inventory.getFreeSpaceCountParrallel = function()
      local total = 0
      inventory.eachEmptySlotParrallel(function()
        total = total + 1
      end)
      return total
    end

    inventory.compactItemStacksParrallel = function()
      if inventory.IS_THIS_TURTLE_INV then
        inventory.compactItemStacks()
      else
        argValidationUtils.tableChecker("self", inventory, {list = {"function"}, PERIPHERAL_NAME = {"string"}, pushItems = {"function"}})
        local tasks = {}
        local taskCount = 0
        for slot in pairs(inventory.list()) do
          taskCount = taskCount + 1
          tasks[taskCount] = function() inventory.pushItems(inventory.PERIPHERAL_NAME, slot) end
        end
        parallel.waitForAll(table.unpack(tasks, 1, taskCount))
      end
    end

    return inventory
  end

  invUtils = {
    inject = inject,
    wrap = inject,
  }
end

local AUTO_HAMMER_NAME = "excompressum:auto_hammer"
local HAMMER_INPUT_SLOT = 1
local HAMMER_OUTPUT_SLOTS = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21}
local HAMMER_HAMMER_SLOTS = {22, 23}

local diamondHammer = { name = "exnihilocreatio:hammer_diamond"}

local HAMMERABLE = {
  ["minecraft:cobblestone"] = true,
  ["minecraft:gravel"] = true,
  ["minecraft:sand"] = true,  
  ["minecraft:netherrack"] = true,
  ["minecraft:concrete"] = true,
  ["minecraft:wool"] = true,
  ["minecraft:stone"] = true,  
  ["minecraft:endstone"] = true,
  ["minecraft:log"] = true,
  ["appliedenergistics2:sky_stone_block"] = true,
}

-- TODO: how to distibute what to rehammer and what to sieve?

local inputChest = invUtils.inject(peripheral.wrap(INPUT_CHEST_NAME) or error("Couldn't find input chest: "..INPUT_CHEST_NAME, 0))
local outputChest = peripheral.wrap(OUTPUT_CHEST_NAME) or error("Couldn't find output chest: "..OUTPUT_CHEST_NAME, 0)

local function addPeripheralName(peripheralName, wrappedPeripheral)
  wrappedPeripheral.PERIPHERAL_NAME = peripheralName
  return wrappedPeripheral
end

local autoHammers = table.pack(peripheral.find(AUTO_HAMMER_NAME, addPeripheralName))

local function add(peripheralList, newPeripheralName)  
  peripheralList.n = peripheralList.n + 1
  peripheralList[peripheralList.n] = peripheral.wrap(newPeripheralName)
  peripheralList[peripheralList.n].PERIPHERAL_NAME = newPeripheralName
end

local function remove(peripheralList, peripheralName)
  for id, p in ipairs(peripheralList) do
    -- find the hole
    if p.PERIPHERAL_NAME == peripheralName then
      -- move the last one to fill the hole
      peripheralList[id] = peripheralList[peripheralList.n]
      peripheralList[peripheralList.n] = nil
      peripheralList.n = peripheralList.n - 1
      break
    end
  end
end

local function dynamicPeripheralManager()
  while true do
    local event, side = os.pullEvent()
    if event == "peripheral" then
      if side:find("hammer") then
        print("attach")
        add(autoHammers, side)
      end
    elseif event == "peripheral_detach" then
      if side:find("hammer") then
        print("detach")
        remove(autoHammers, side)
      elseif side == INPUT_CHEST_NAME or side == OUTPUT_CHEST_NAME then
        error("Required peripheral detached, peripheral name: "..side)
      end
    end
  end
end

local function loadHammers()
  -- TODO: optimise
  for _, autoHammer in ipairs(autoHammers) do
    for _, hammerSlot in pairs(HAMMER_HAMMER_SLOTS) do
      if not autoHammer.getItem(hammerSlot) then
        for inputSlot in inputChest.eachSlotWithItem(diamondHammer) do
          inputChest.pushItems(autoHammer.PERIPHERAL_NAME, inputSlot, 1, hammerSlot)
        end
      end
    end
  end
end

local function loadBlocks()
  for inputSlot, item in inputChest.eachSlotSkippingEmpty() do
    for _, autoHammer in ipairs(autoHammers) do
      if not autoHammer.getItem(HAMMER_INPUT_SLOT) then
        if HAMMERABLE[item.name] then
          inputChest.pushItems(autoHammer.PERIPHERAL_NAME, inputSlot, nil, HAMMER_INPUT_SLOT)
        end
      end
    end
  end
end

local function empty()
  for _, autoHammer in ipairs(autoHammers) do
    for slot in pairs(HAMMER_OUTPUT_SLOTS) do
      autoHammer.pushItems(OUTPUT_CHEST_NAME, slot) -- TODO: inteligent looping of cobble outputs?
    end
  end
end



local function passThroughJunk()
  for slot, item in inputChest.eachSlotSkippingEmpty() do
    if not (HAMMERABLE[item.name] or diamondHammer.name == item.name) then
      inputChest.pushItems(OUTPUT_CHEST_NAME, slot)
    end
  end
end

local function main()
  while true do
    loadHammers()
    loadBlocks()
    empty()
    if PASS_THROUGH_JUNK then
      passThroughJunk()
    end
  end
end

parallel.waitForAny(dynamicPeripheralManager, main)