local simpleModeConfig = {
  -- simple mode toggles:
  suckFunc = turtle.suckDown,
  dropFunc = turtle.dropUp,
  threeXThreeMode = true, -- true for 3x3 crafts, false for 2x2
}

if peripheral.find("modem") then
  -- complex mode, requires plethora
else
  local suckFunc = simpleModeConfig.suckFunc
  local dropFunc = simpleModeConfig.dropFunc
  local threeXThreeMode = simpleModeConfig.threeXThreeMode

  local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
  local twoXTwoSlots = {1,2,5,6}
  local slots

  if threeXThreeMode then
    slots = threeXThreeSlots
  else
    slots = twoXTwoSlots
  end

  local function drop()
    local sleepTime = 1
    turtle.select(16)
    while turtle.getItemCount(16) > 0 do
      dropFunc()
      os.sleep(sleepTime)
      sleepTime = sleepTime + math.floor(sleepTime/2) +1
    end
  end


  while true do
    drop()

    -- TODO: make item pulling faster, pull more and distibute?
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
end
