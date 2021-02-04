settings.define("lupus590.cobble_gen.drop_side", {
  description = "The side to auto output cobble into. [ top | bottom | front | no_auto_out]",
  type = "string",
})

settings.define("lupus590.cobble_gen.dig_side", {
  description = "The side to dig. [ top | bottom | front ]",
  type = "string",
})

settings.save()
settings.load()

local dropSide = settings.get("lupus590.cobble_gen.drop_side", "no_auto_out")
local digSide = settings.get("lupus590.cobble_gen.dig_side")

dropSide = dropSide and dropSide:lower()
digSide = digSide and digSide:lower()

if (not dropSide) or (dropSide ~= "top" and dropSide ~= "bottom" and dropSide ~= "front" and dropSide ~= "no_auto_out") then
  error("Drop side is not set, use the set command and set lupus590.cobble_gen.drop_side to a valid side.", 0)
end

if (not digSide) or (digSide ~= "top" and digSide ~= "bottom" and digSide ~= "front") then
  error("Dig side is not set, use the set command and set lupus590.cobble_gen.dig_side to a valid side.", 0)
end

local drop = {
  top = turtle.dropUp,
  bottom = turtle.dropDown,
  front = turtle.drop,
}

local dig = {
  top = turtle.digUp,
  bottom = turtle.digDown,
  front = turtle.dig,
}


local dropFunc = drop[dropSide]
local digFunc = dig[digSide]
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

local function cobbleGen()
  while true do
    if not allFull() then
      digFunc()
      sleep(1)
    else
      print("Digging paused due to full inventory, remove blocks to resume.")
      os.pullEvent("turtle_inventory")
      print("Detected inventory change, attemting to resume digging.")
    end
  end
end


parallel.waitForAll(cobbleGen, emptyAll)
