-- While some of these can be used directly as a filter, these are much better as utilities within a custom filter.
-- There's no reason that you can't have a filter functions that calls other filters to perform complex filtering logic.
 -- TODO: fluids compatability for the filters, most filters probably can do both
 -- TODO: some may not work correctly when items are across different slots
 -- TODO: expect

 --- An output filter that keeps quantityToKeep items in the inventory while allowing extra items to be pulled out.
 ---@param item {count : number} The item filter.
 ---@param quantityToKeep number The number of items to keep.
 ---@return boolean . If items are allowed to be pulled out.
 ---@return number . How many items are allowed to be pulled out.
local function keepQuantityFilter(item, quantityToKeep)
    local limit = item.count - quantityToKeep
    limit = math.max(limit, 0)
    return limit > 0, limit
end

--- A wrapper around keepQuantityFilter that keeps 64 items.
---@param item {count : number} The item to filter.
---@return boolean . If items are allowed to be pulled out.
---@return number . How many items are allowed to be pulled out.
local function keepAStackFilter(item)
    return keepQuantityFilter(item, 64)
end

--- An output filter that only allows the query item to be pulled out if it is the highest quantity that currently is in the inventory.
---@param queryItem {count : number, name: string} The current item that we are testing in the filter.
---@param peripheralName  string The name of the inventory that we are filtering.
---@param priorityList { [1] : {name :string}} The order to allow items out.
---@return boolean . True if the item is allowed to be pulled out.
local function prioritiseItemsInOrderFilter(queryItem, peripheralName, priorityList) -- TODO: allow things to have the same priority
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

--- An input filter to prevent insertingmore than the maxCount of an item.
---@param itemName string The name of the item to be filtered.
---@param peripheralName string The name of the peripheral that the filter is applied to.
---@param maxCount number The maximum number of items to keep in this inventory.
---@return number . The number of items that are allowed to be inserted.
local function overFlowPreventer(itemName, peripheralName, maxCount)
    for _, item in pairs(peripheral.call(peripheralName, "list")) do
        if item.name == itemName then
            return maxCount - item.count
        end
    end
	return maxCount > 0, maxCount
end

return {
	keepQuantityFilter = keepQuantityFilter,
	keepAStackFilter = keepAStackFilter,
	prioritiseItemsInOrderFilter = prioritiseItemsInOrderFilter,
	overFlowPreventer = overFlowPreventer,
}
