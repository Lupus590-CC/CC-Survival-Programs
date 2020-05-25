local suckFunc = turtle.suckDown
local dropFunc = turtle.dropUp
local threeXThreeMode = true -- true for 3x3 crafts, false for 2x2
local maxWaitTime = 120 -- when the output chest is fuil we wait a short amount
-- of time, if it still is full then we wait longer. This value it the maximum
-- amount of time to wait before checking again
local inputChestSide = "bottom" -- optional, speeds up pulling items. Doesn't have to be a chest, but must be an inventory

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}
local slots

if threeXThreeMode then
  slots = threeXThreeSlots
else
  slots = twoXTwoSlots
end

local inputChest = peripheral.wrap(inputChestSide)

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

  local amountToPull = 1
  if inputChest and inputChest.list then
    repeat
      local total = 0
      for _, item in pairs(inputChest.list()) do
        total = total + item.count
      end
      if threeXThreeMode then
        amountToPull = math.floor(total/9)
      else
        amountToPull = math.floor(total/4)
      end
      amountToPull = math.min(amountToPull, 64)
    until amountToPull > 0
  end

  for _, slot in ipairs(slots) do
    local currentCount = turtle.getItemCount(slot)
    if currentCount < amountToPull then
      turtle.select(slot)
      while not suckFunc(amountToPull - currentCount) do end
    end
  end

  turtle.select(16)
  if not turtle.craft() then
    printError("Bad inventory, please fix and press any key to resume")
    os.pullEvent("key")
  end
end
