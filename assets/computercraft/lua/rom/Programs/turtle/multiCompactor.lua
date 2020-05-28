local theme = {
  header = {
    fg = colours.black,
    bg = colours.grey,
  },
  footer = {
    fg = colours.black,
    bg = colours.grey,
  },
  selectedRow = {
    fg = colours.white,
    bg = colours.black,
  },
  row = {
    fg = colours.grey,
    bg = colours.black,
  },
  main =  {
    fg = colours.white,
    bg = colours.black,
  },
}

local w,h = term.getSize()
local win = window.create(term.current(), 1, 1, w, h)
term.redirect(win) -- really we should capture the old term but everything seems fine when we don't restore it and we don't need it so we just let it disappear into the aether
local rowWin = window.create(win, 1,2, w, h-3)

local configFileName = shell.getRunningProgram()..".config"
local recipeFileName = shell.getRunningProgram()..".recipe"

local recipes
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
  },]].."\n}")
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

local minToPull -- tODO: rewrite
if threeXThreeMode then
  slots = threeXThreeSlots
  minToPull = 9
else
  slots = twoXTwoSlots
  minToPull = 4
end

local function renderHeader()
  term.setCursorPos(1,1)
  term.setBackgroundColour(theme.header.bg)
  term.setTextColour(theme.header.fg)
  term.clearLine()
  term.setCursorPos(1,1)
  write(" Mode | Internal Name")
end

local function renderFooter()
  local _, h = term.getSize()
  term.setCursorPos(1,h-1)
  term.setBackgroundColour(theme.footer.bg)
  term.setTextColour(theme.footer.fg)
  term.clearLine()
  term.setCursorPos(1,h-1)
  write("Arrow keys to select a row.")
  print()
  term.clearLine()
  term.setCursorPos(1,h)
  write("Press 2 or 3 to set mode.")
end

local function renderRow(row, selected)
  if selected then
    term.setBackgroundColour(theme.selectedRow.bg)
    term.setTextColour(theme.selectedRow.fg)
    write(">")
  else
    term.setBackgroundColour(theme.row.bg)
    term.setTextColour(theme.row.fg)
    write(" ")
  end
  if recipes[row] == 3 then
    write("3x3 ")
  elseif recipes[row] == 2 then
    write("2x2 ")
  else
    write("    ")
  end
  write(" | "..row)
end

local function renderRows()
  local oldTerm = term.redirect(rowWin)
  term.setBackgroundColour(theme.main.bg)
  term.setTextColour(theme.main.fg)
  term.clear()
  local rowNum = 1
  for recipe in pairs(recipes or {}) do
    term.setCursorPos(1,rowNum)
    renderRow(recipe, true)
    rowNum = rowNum + 1
  end
  term.redirect(oldTerm)
end

local function doUi()
  while true do
    win.setVisible(false)
    term.setBackgroundColour(theme.main.bg)
    term.setTextColour(theme.main.fg)
    term.clear()
    renderHeader()
     -- TODO: selection
     -- TODO: paging
    renderRows()
    renderFooter()
    win.setVisible(true)
    os.pullEvent("key")
  end
end

local function pullInput()
  local pulled = false
  repeat
    -- compact input chest
    for slot in pairs(inputChest.list()) do
      inputChest.pushItems(inputChest.PERIPHERAL_NAME, slot)
    end
    for slot, item in pairs(inputChest.list()) do
      -- TODO: read the recipe to calculate the amount to pull
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
  -- TODO: read the recipe to calculate the mode to use
  if threeXThreeMode then
    amountToPull = math.floor(total/9)
  else
    amountToPull = math.floor(total/4)
  end
  amountToPull = math.min(amountToPull, 64)

  -- TODO: read the recipe to calculate the slots to use
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

local function compact()
  -- clean inventory
  for _, slot in pairs(threeXThreeSlots) do
    turtle.select(slot)
    dropFunc()
  end

  while true do
    pullTurtle()
    turtle.select(16)
    if turtle.getItemCount(1) > 0 and not turtle.craft() then
      -- TODO: rewrite for UI
      printError("Bad inventory, empty turtle chest and turtle then press any key to resume")
      os.pullEvent("key")
      print("resuming")
    end
    if turtle.getItemCount(16) > 0 then
      pushOutput()
    end
    pullInput()
  end
end

local function loadRecipe()
  local function unsafeload()
    local file = fs.open(recipeFileName, "r")
    recipes = textutils.unserialize(file.readAll())
    file.close()
  end

  if (not fs.exists(recipeFileName)) or fs.isDir(recipeFileName) then
    return false, "not a file"
  end

  return pcall(unsafeload)
end

local function saveRecipe()
  local function unsafeSave()
    local file = fs.open(recipeFileName, "w")
    file.write(recipes)
    file.close()
  end

  return pcall(unsafeSave)
end

local function itemScanner()
  recipes = {
    ["minecraft:cobblestone"] = 3,
    ["minecraft:stone"] = 2,
    ["minecraft:woodPlanks"] = 1,
  }
  while true do

    sleep(10000)
  end
end

parallel.waitForAll(doUi, itemScanner, compact)
