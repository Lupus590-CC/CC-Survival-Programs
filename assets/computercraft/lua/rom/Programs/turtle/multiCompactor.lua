-- complex mode, requires plethora
local configFileName = shell.getRunningProgram()..".config"
local config = {
  input = "peripheralAddressHere, eg minecraft:chest_1",
  output = "peripheralAddressHere, eg minecraft:chest_2",
  turtleNeighbour = {
    address = "peripheralAddressHere, eg minecraft:chest_3"
    .." the turtle needs to be able to access this directly",
    pos = "top/bottom/front",
  }
}
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

local function saveConfig()
  local function unsafeSave()
    local file = fs.open(configFileName, "w")
    file.write(textutils.serialize(config))
    file.close()
  end

  return pcall(unsafeSave)
end

local ok, data = loadConfig()
if (not ok) and data == "not a file" then
  local ok, err = saveConfig()
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

local function pushOutput()
  turtle.select(16)
  dropFunc()
  while pairs(turtleChest.list())(turtleChest.list()) do
    -- bit of a hack for while items in inventory
    turtleChest.pushItems(outputChest.PERIPHERAL_NAME, 1)
  end
end

-- clean inventory
if turtle.getItemCount(16) > 0 then
  pushOutput()
end
for _, slot in pairs(threeXThreeSlots) do
  if turtle.getItemCount(slot) > 0 then
    turtle.select(slot)
    dropFunc()
  end
end


-- TODO: actually do stuff
-- TODO: how to tell which mode to use?
