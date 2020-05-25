-- complex mode, requires plethora
local configFileName = shell.getRunningProgram()..".config"
local config = {
  input = "peripheralAddressHere, eg minecraft:chest_1",
  output = "peripheralAddressHere, eg minecraft:chest_2",
  turtleNeighbour = {
    address = "peripheralAddressHere, eg minecraft:chest_3 the turtle needs to be able to access this directly",
    pos = "up/down/front",
  }
}
local inputChest
local outputChest
local turtleChest

local function loadConfig()
  local function unsafeload()
    local file = fs.open(configFileName, "r")
    local config = textutils.unserialize(file.readAll())
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
  -- TODO: init setup, ask user to place items to identify chests
  local ok, err = saveConfig()
  if not ok then
    error("Could not save config file.\n Got error: "..err,0)
  end
end

local inputChest = peripheral.wrap(config.input) or error("Bad config, could not find input chest: "..config.input)
local outputChest = peripheral.wrap(config.output) or error("Bad config, could not find output chest: "..config.output)
local turtleChest = peripheral.wrap(config.turtleNeighbour.address) or error("Bad config, could not find turtle chest: "..config.turtleNeighbour.address)

inputChest.PERIPHERAL_NAME = config.input
outputChest.PERIPHERAL_NAME = config.output
turtleChest.PERIPHERAL_NAME = config.turtleNeighbour.address
turtleChest.POSITION = config.turtleNeighbour.pos

-- TODO: actually do stuff
-- TODO: how to tell modes
