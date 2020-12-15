local itemPipe = require("item_pipe")

local pipe = itemPipe.newPipe("minecraft:chest_57") -- this is the source inventory

pipe.setFilter(function (item, slot) -- item is from inv.list(), slot is the slot number that the item is in
  local allowIn, limit = true, 5 -- we can prevent things being extracted and how many are
  return allowIn, limit
end)

pipe.addDestination("minecraft:chest_56").setFilter(function(item) -- unlike the ouput filter input doesn't get slot info
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

