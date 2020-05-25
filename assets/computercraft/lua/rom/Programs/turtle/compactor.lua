local suckFunc = turtle.suckDown
local dropFunc = turtle.dropUp
local threeXThreeMode = true -- true for 3x3 crafts, false for 2x2
local maxWaitTime = 120 -- when the output chest is fuil we wait a short amount
-- of time, if it still is full then we wait longer. This value it the maximum
-- amount of time to wait before checking again

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}
local slots

if threeXThreeMode then
  slots = threeXThreeSlots
else
  slots = twoXTwoSlots
end

while true do
  local sleepTime = 0
  turtle.select(16)
  while turtle.getItemCount(16) > 0 do
    if not dropFunc() then
      local _, y = term.getCursorPos()
      term.setCursorPos(1, y)
      sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
      write("Output full, waiting "..tostring(sleepTime).." seconds.")
      os.sleep(sleepTime)
    end
  end
  if sleepTime > 0 then
    print("Continuing")
  end

  -- TODO: make item pulling faster, pull more and distibute?
  -- wrap the chest to find out how many items are in it to
  -- calculate how many to pull at a time
  for _, slot in ipairs(slots) do
    if turtle.getItemCount(slot) == 0 then
      turtle.select(slot)
      while not suckFunc(1) do end
    end
  end

  turtle.select(16)
  if not turtle.craft() then
    printError("Bad inventory, please fix and press any key to resume")
    os.pullEvent("key")
  end
end
