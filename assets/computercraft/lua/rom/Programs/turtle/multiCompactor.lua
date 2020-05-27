-- complex mode, requires plethora
local configFileName = shell.getRunningProgram()..".config"
local config
local inputChest
local outputChest
local turtleChest

local function loadConfig()
  local function unsafeload()
    local file = fs.open(configFileName, "r")
    config = textutils.unserialize(file.readAll())
    file.close()
  end

  if (not fs.exists(configFileName)) or fs.isDir(configFileName) then
    return false, "not a file"
  end

  return pcall(unsafeload)
end

local function createConfig()
  local function unsafeSave()
    local file = fs.open(configFileName, "w")
    file.write([[{
  input = "minecraft:chest_1",
  output = "minecraft:chest_2",
  turtleNeighbour = {
    address = "minecraft:chest_3", -- the turtle needs to be able to access this directly
    pos = "top", -- relative to the turtle, top/bottom/front
  },
  threeXThreeMode = true, -- false for 2x2 craft
}]]) -- TODO: detect mode to use before pulling blocks
    file.close()
  end

  return pcall(unsafeSave)
end

local ok, data = loadConfig()
if (not ok) and data == "not a file" then
  local ok, err = createConfig()
  if not ok then
    error("Could not save config file.\n Got error: "..err,0)
  end
  print("Edit config file to continue. Find the config at:\n"..configFileName)
  return
end

local inputChest = peripheral.wrap(config.input)
or error("Bad config, could not find input chest: "..config.input)
local outputChest = peripheral.wrap(config.output)
or error("Bad config, could not find output chest: "..config.output)
local turtleChest = peripheral.wrap(config.turtleNeighbour.address)
or error("Bad config, could not find turtle chest: " ..config.turtleNeighbour.address)

inputChest.PERIPHERAL_NAME = config.input
outputChest.PERIPHERAL_NAME = config.output
turtleChest.PERIPHERAL_NAME = config.turtleNeighbour.address
turtleChest.POSITION = config.turtleNeighbour.pos:lower()
threeXThreeMode = config.threeXThreeMode

local _, block, suckFunc, dropFunc
if turtleChest.POSITION == "up" or turtleChest.POSITION == "top" then
  _, block = turtle.inspectUp()
  suckFunc = turtle.suckUp
  dropFunc = turtle.dropUp
elseif turtleChest.POSITION == "down" or turtleChest.POSITION == "bottom" then
  _, block = turtle.inspectDown()
  suckFunc = turtle.suckDown
  dropFunc = turtle.dropDown
elseif turtleChest.POSITION == "front" or turtleChest.POSITION == "forward"
or turtleChest.POSITION == "forwards" then
  _, block = turtle.inspect()
  suckFunc = turtle.suck
  dropFunc = turtle.drop
else
  error("Bad config, turtleNeighbour.pos is an invalid side. Expected up, down" .." or front. Got "..turtleChest.POSITION)
end

if (not block) or block.name ~=  "minecraft:chest" then
  error("Could not find turtle neighbour chest, side checked"
  ..turtleChest.POSITION)
end

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}

local minToPull
if threeXThreeMode then
  slots = threeXThreeSlots
  minToPull = 9
else
  slots = twoXTwoSlots
  minToPull = 4
end

local function pullInput()
  local pulled = false
  repeat
    -- compact input chest
    for slot in pairs(inputChest.list()) do
      inputChest.pushItems(inputChest.PERIPHERAL_NAME, slot)
    end
    for slot, item in pairs(inputChest.list()) do
      if item.count >= minToPull then
        local limit = math.floor(item.count/minToPull)*minToPull
        inputChest.pushItems(turtleChest.PERIPHERAL_NAME, slot, limit)
        pulled = true
        break
      end
    end
  until pulled
end

local function pullTurtle()
  local amountToPull = 1
  local total = 0
  for _, item in pairs(turtleChest.list()) do
    total = total + item.count
  end
  if threeXThreeMode then
    amountToPull = math.floor(total/9)
  else
    amountToPull = math.floor(total/4)
  end
  amountToPull = math.min(amountToPull, 64)

  for _, slot in ipairs(slots) do
    local currentCount = turtle.getItemCount(slot)
    if currentCount < amountToPull then
      turtle.select(slot)
      suckFunc(amountToPull - currentCount)
    end
  end
end

local function pushOutput()
  turtle.select(16)
  dropFunc()
  for slot in pairs(turtleChest.list()) do
    turtleChest.pushItems(outputChest.PERIPHERAL_NAME, slot)
  end
end

-- clean inventory
for _, slot in pairs(threeXThreeSlots) do
  turtle.select(slot)
  dropFunc()
end

while true do
  pullTurtle()
  turtle.select(16)
  if turtle.getItemCount(1) > 0 and not turtle.craft() then
    printError("Bad inventory, empty turtle chest and turtle then press any key to resume")
    os.pullEvent("key")
    print("resuming")
  end
  if turtle.getItemCount(16) > 0 then
    pushOutput()
  end
  pullInput()
end
