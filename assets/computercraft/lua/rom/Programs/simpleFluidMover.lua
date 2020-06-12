local DESTINATION_NAME = "minecraft:gc fluid tank_0"
local SOURCE_NAME = "minecraft:block_crucible_0"
local TIME_TO_SLEEP = 1

local source = peripheral.wrap(SOURCE_NAME)

while true do
  local ok, sourceTank = pcall(source.getTanks)
  if ok and sourceTank and sourceTank[1] and sourceTank[1].name then
    local fluidToMove = sourceTank [1].name
    source.pushFluid(DESTINATION_NAME, nil, fluidToMove)
  else
    sleep(TIME_TO_SLEEP)
  end
end