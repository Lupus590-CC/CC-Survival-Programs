local suckFunc = turtle.suckUp
local dropFunc = turtle.dropDown

local toConvertItems = { ["minecraft:gravel"] = true}

while true do
  if turtle.getItemCount() == 0 and not turtle.detect() then
    suckFunc(1)
  end
  turtle.place()
  turtle.dig()
  local item = turtle.getItemDetail()
  if item and not toConvertItems[item.name] then
    dropFunc()
  end
end
