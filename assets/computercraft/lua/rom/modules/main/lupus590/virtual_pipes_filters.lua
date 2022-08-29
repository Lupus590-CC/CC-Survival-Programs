-- While some of these can be used directly as a filter, these are much better as utilities within a custom filter.
-- There's no reason that you can't have a filter functions that calls other filters to perform complex filtering logic.
 -- TODO: fluids compatability for the filters, most filters probably can do both

local function keepQuantityFilter(item, quantityToKeep)
    local limit = item.count - quantityToKeep
    limit = math.max(limit, 0)
    return limit > 0, limit
end

local function keepAStackFilter(item)
    return keepQuantityFilter(item, 64)
end

local function prioritiseItemsInOrderFilter(queryItem, _slot, peripheralName, priorityList)
    -- If the peripheral has an item higher on the list than the query item then don't allow the transfer

    if queryItem.name == priorityList[1] then
        return true
    end

    local queryItemPriority = math.huge
    for priority, itemName in ipairs(priorityList) do
        if queryItem.name == itemName then
            queryItemPriority = priority
            break
        end
    end

    local priorityIndex = {}
    for k, v in ipairs(priorityList) do
        priorityIndex[v] = k
    end

    local itemsInInventory = peripheral.call(peripheralName, "list")
    for _, item in pairs(itemsInInventory) do
      if priorityIndex[item.name] and priorityIndex[item.name] < queryItemPriority then
        return false -- do not allow the query item to be moved
      end
    end
    return true
end

return {
	keepQuantityFilter = keepQuantityFilter,
	keepAStackFilter = keepAStackFilter,
	prioritiseItemsInOrderFilter = prioritiseItemsInOrderFilter,
}
