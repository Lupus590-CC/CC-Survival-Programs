local suckChestFunc = turtle.suckUp
local dropChestFunc = turtle.drop
local dropWaterFunc = turtle.dropDown
local suckWaterFunc = turtle.suckDown
local waitTime = 120

local growingName = "appliedenergistics2:crystal_seed"

while true do
  while suckWaterFunc() do end
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and item.name ~= growingName then
      turtle.select(i)
      dropChestFunc()
    elseif item then
      turtle.select(i)
      dropWaterFunc()
    end
  end
  while suckChestFunc() do
    dropWaterFunc()
  end
  sleep(waitTime)
end
