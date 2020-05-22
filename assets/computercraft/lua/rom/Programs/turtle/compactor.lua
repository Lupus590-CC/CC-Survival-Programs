local suckFunc = turtle.suckDown
local dropFunc = turtle.dropUp
local threeXThreeMode = true -- true for 3x3 crafts, false for 2x2

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}
local slots

if threeXThreeMode then
  slots = threeXThreeSlots
else
  slots = twoXTwoSlots
end

while true do
  for _, slot in ipairs(slots) do
    if turtle.getItemCount(slot) == 0 then
      turtle.select(slot)
      while not suckFunc(1) do end
    end
  end
  if not turtle.craft() then
    error("Bad inventory, please empty me")
  end
  local sleepTime = 1
  while not dropFunc() do
    os.sleep(sleepTime)
    sleepTime = sleepTime + math.floor(sleepTime/2) +1
  end
end
      
