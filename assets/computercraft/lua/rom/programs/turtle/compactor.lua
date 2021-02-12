settings.define("lupus590.compactor.drop_side", {
  description = "The side to output into. [ top | bottom | front ]",
  type = "string",
})

settings.define("lupus590.compactor.suck_side", {
  description = "The side to input from. [ top | bottom | front ]",
  type = "string",
})

settings.define("lupus590.compactor.craft_mode", {
  description = "The side to dig. [ 2x2 | 3x3 ]",
  type = "string",
})

settings.save()
settings.load()

local dropSide = settings.get("lupus590.compactor.drop_side")
local suckSide = settings.get("lupus590.compactor.suck_side")
local craftMode = settings.get("lupus590.compactor.craft_mode")

dropSide = dropSide and dropSide:lower()
suckSide = suckSide and suckSide:lower()

if (not dropSide) or (dropSide ~= "top" and dropSide ~= "bottom" and dropSide ~= "front") then
  error("Drop side is not set, use the set command and set lupus590.compactor.drop_side to a valid side.", 0)
end

if (not suckSide) or (suckSide ~= "top" and suckSide ~= "bottom" and suckSide ~= "front") then
  error("Suck side is not set, use the set command and set lupus590.compactor.suck_side to a valid side.", 0)
end

if (not craftMode) or (craftMode ~= "2x2" and craftMode ~= "3x3") then
  error("Craft mode is not set, use the set command and set lupus590.compactor.craftMode to a valid mode.", 0)
end

local drop = {
  top = turtle.dropUp,
  bottom = turtle.dropDown,
  front = turtle.drop,
}

local suck = {
  top = turtle.suckUp,
  bottom = turtle.suckDown,
  front = turtle.suck,
}

local suckFunc = suck[suckSide]
local dropFunc = drop[dropSide]
local maxWaitTime = 120
local inputChestSide = suckSide

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}
local slots

if craftMode == "3x3" then
  slots = threeXThreeSlots
else -- 2x2
  slots = twoXTwoSlots
end

local inputChest = peripheral.wrap(inputChestSide)

while true do
  local sleepTime = 0
  turtle.select(16)
  -- TODO: fix multi output
  while turtle.getItemCount(16) > 0 do
    if not dropFunc() then
      local _, y = term.getCursorPos()
      term.setCursorPos(1, y)
      sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
      write("Output full, waiting "..tostring(sleepTime).." seconds.")
      sleep(sleepTime)
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
      if craftMode == "3x3" then
        amountToPull = math.floor(total/9)
      else -- 2x2
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
