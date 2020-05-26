local dropFunc = turtle.dropUp -- set to nil to disable auto eject
local maxWaitTime = 120

local function allFull()
  for i = 1, 16 do
    if turtle.getItemCount(i) == 0 or turtle.getItemSpace(i) < 0 then
      return false
    end
  end
  return true
end

local function emptyAll()
  while dropFunc do
    for i = 1, 16 do
      local sleepTime = 0
      local _, y = term.getCursorPos()
      turtle.select(i)
      while turtle.getItemCount(i) > 0 and (not dropFunc())
      and turtle.getItemCount(i) > 0 do -- check twice as drop may not drop everything
        term.setCursorPos(1, y)
        sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
        write("Output full, waiting "..tostring(sleepTime).." seconds.")
        os.sleep(sleepTime)
      end
      if sleepTime > 0 then
        print("Continuing output")
      end
    end
  end
end

local function dig()
  while true do
    if not allFull() then
      turtle.dig()
    else
      print("Digging paused due to full inventory, remove blocks to resume.")
      os.pullEvent("turtle_inventory")
      print("Detected inventory change, attemting to resume digging.")
    end
  end
end


parallel.waitForAll(dig, emptyAll)
