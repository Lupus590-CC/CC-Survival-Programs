local itemPipe = require("lupus590.item_pipe")

local pipe = itemPipe.newPipe()

pipe.addSource("minecraft:chest_57").setFilter(function (item, slot, name) -- item is from inv.list(), slot is the slot number that the item is in, name is the peripheral name of the chest that the filter is on this can be useful when filters are shared for multipel inventories
    local allowIn, limit = true, 5 -- we can prevent things being extracted and how many are
    return allowIn, limit
end).setPriority(1) -- sources also have priorities, lower priorities are extracted first

pipe.addDestination("minecraft:chest_56").setFilter(function(item, _, name) -- unlike the output filter input doesn't get slot info, _ is always nil allows for input filters to also be output filters, name is the peripheral name of the chest tat the filter is on
    if item.name == "minecraft:cobblestone" then
	    local allowIn, limit, slot = true, 1, 5 -- slot is the destination slot if the item gets moved
  	    return allowIn, limit, slot -- if the source also has a limit then the lower is used
    else
    	return true
    end
end) -- by defualt all items are allowed into any slot with limit as the whole stack

pipe.addDestination("minecraft:chest_55").setPriority(1) -- lower numbers go earlier, the defualt is 0, negatives are fine

local builtPipe = pipe.build()

while true do
    builtPipe.tick() -- go through the source once attempting to move the items
    sleep(1)
end

