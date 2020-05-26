local dropFunc = turtle.dropUp -- set to nil to disable auto eject

local function allFull()
  for i = 1, 16 do
    if turtle.getItemSpace(i) > 0 then
      return false
    end
  end
  return true
end

local function emptyAll()
  for i = 1, 16 do
    local sleepTime = 0
    local _, y = term.getCursorPos()
    turtle.select(i)
    while turtle.getItemSpace(i) > 0 and (not dropFunc())
    and turtle.getItemSpace(i) > 0 do -- check twice as drop may not drop everything
      term.setCursorPos(1, y)
      sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
      write("Output full, waiting "..tostring(sleepTime).." seconds.")
      os.sleep(sleepTime)
    end
    if sleepTime > 0 then
      print("Continuing")
    end
  end
end

while true do
  while allFull() do
    if dropFunc then
      emptyAll()
    else
      print("Paused due to full inventory, remove blocks to resume.")
      os.pullEvent("turtle_inventory")
      print("Detected inventory change, attemting to resume.")
    end
  end
  turtle.dig()
end
