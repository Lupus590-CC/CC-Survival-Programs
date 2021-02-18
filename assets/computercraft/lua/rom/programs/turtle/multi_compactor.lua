local theme = { -- TODO: use config module for this? or settings? or just let them edit here?
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
	error =  {
		fg = term.isColour() and colours.red or colours.black,
		bg = colours.black,
	},
}

settings.define("lupus590.multi_compactor.output_chest_name", {
	description = "The network address of the inventory to output into. (E.G. minecraft:chest_0)",
	type = "string",
})

settings.define("lupus590.multi_compactor.input_chest_side", {
	description = "The network address of the inventory take input from. (E.G. minecraft:chest_0)",
	type = "string",
})

-- TODO: rewrite to use remote turtle name?
settings.define("lupus590.multi_compactor.working_chest_name", {
	description = "The network address of the inventory to work in. (E.G. minecraft:chest_0)",
	type = "string",
})

settings.define("lupus590.multi_compactor.working_chest_side", {
	description = "The side of the turtle that the working inventory is on. [ top | bottom | front ]",
	type = "string",
})

settings.save()
settings.load()

local dropSide = settings.get("lupus590.multi_compactor.working_chest_side")
local suckSide = settings.get("lupus590.multi_compactor.working_chest_side")

dropSide = dropSide and dropSide:lower()
suckSide = suckSide and suckSide:lower()

if (not dropSide) or (dropSide ~= "top" and dropSide ~= "bottom" and dropSide ~= "front") then
	error("Drop side is not set, use the set command and set lupus590.multi_compactor.working_chest_side to a valid side.", 0)
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


local function getConfigLocation(fileName) -- tries to place config next to program, avoiding read only locations and the startup directory and going for root instead
	local programDir = fs.getDir(shell.getRunningProgram())
	if fs.isReadOnly(programDir) or programDir:lower() == "startup" then
		return fileName
	else
		return fs.combine(fs.getDir(shell.getRunningProgram()), fileName)
	end
end

-- TODO: debug recipe duplication, maybe replace how they are saved
local recipeFileName = getConfigLocation("multi_compactor.recipes")

local recipes

local inputChest = peripheral.wrap(settings.get("lupus590.multi_compactor.input_chest_side"))
or error("Bad config, could not find input chest: "..settings.get("lupus590.multi_compactor.input_chest_side"))
local outputChest = peripheral.wrap(settings.get("lupus590.multi_compactor.output_chest_name"))
or error("Bad config, could not find output chest: "..settings.get("lupus590.multi_compactor.output_chest_name"))
local turtleChest = peripheral.wrap(settings.get("lupus590.multi_compactor.working_chest_name"))
or error("Bad config, could not find turtle chest: " ..settings.get("lupus590.multi_compactor.working_chest_name"))

inputChest.PERIPHERAL_NAME = settings.get("lupus590.multi_compactor.input_chest_side") -- TODO: peripheral.getName
outputChest.PERIPHERAL_NAME = settings.get("lupus590.multi_compactor.output_chest_name") -- TODO: peripheral.getName
turtleChest.PERIPHERAL_NAME = settings.get("lupus590.multi_compactor.working_chest_name") -- TODO: peripheral.getName

local w, h = term.getSize()
local win = window.create(term.current(), 1, 1, w, h)
local pageSize = h-3
local rowWin = window.create(win, 1,2, w, pageSize)
term.redirect(win) -- really we should capture the old term but everything seems fine when we don't restore it and we don't need it so we just let it disappear into the aether

local threeXThreeSlots = {1,2,3,5,6,7,9,10,11}
local twoXTwoSlots = {1,2,5,6}
local pageCount = 1

local function renderHeader(pageNumber)
	term.setCursorPos(1,1)
	term.setBackgroundColour(theme.header.bg)
	term.setTextColour(theme.header.fg)
	term.clearLine()
	term.setCursorPos(1,1)
	write(" Mode | Internal Name | page "..pageNumber.." of "..pageCount)
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
	write("Press 2 or 3 to set mode. 1 to remove.")
end

local function renderRow(row, isSelected)
	if isSelected then
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

local function renderRows(selected, page)
	local oldTerm = term.redirect(rowWin)
	term.setBackgroundColour(theme.main.bg)
	term.setTextColour(theme.main.fg)
	term.setCursorPos(1,1)
	term.clear()
	if recipes.n and recipes.n > 0 then
		for i = 1, pageSize do
			local itemToDisplay = pageSize*(page-1)+i
			if recipes[itemToDisplay] then
				term.setCursorPos(1, i)
				renderRow(recipes[itemToDisplay], selected == i)
			end
		end
	end
	term.redirect(oldTerm)
end

local function renderError(e)
	win.setVisible(false)
	term.setCursorPos(1,1)
	term.setBackgroundColour(theme.error.bg)
	term.setTextColour(theme.error.fg)
	term.clear()
	term.setCursorPos(1,1)
	write(e)
	win.setVisible(true)
	os.pullEvent("key")
	os.queueEvent("compact_resume")
end

local function saveRecipes()
	local function unsafeSave()
		local file = fs.open(recipeFileName, "w")
		file.writeLine("{")
		for _, v in ipairs(recipes) do
			file.writeLine("[\""..v.."\"]="..recipes[v]..",")
		end
		file.writeLine("}")
		file.close()
	end

	return pcall(unsafeSave)
end

local function doUi()
	local selected = 1
	local page = 1
	while true do
		win.setVisible(false)
		term.setCursorPos(1,1)
		term.setBackgroundColour(theme.main.bg)
		term.setTextColour(theme.main.fg)
		term.clear()
		pageCount = math.max(math.ceil((recipes.n or 1)/(pageSize or 1)),1)
		renderHeader(page)
		renderRows(selected, page)
		renderFooter()
		win.setVisible(true)
		local event = table.pack(os.pullEvent())
		if event[1] == "compact_error" then
			renderError(event[2])
		elseif event[1] == "key" then
			if event[2] == keys.up and not event[3] then
				if selected == 1 and page > 1 then
					page = page -1
					selected = pageSize
				else
					selected = math.max(selected - 1, 1)
				end
			elseif event[2] == keys.down and not event[3] then
				if selected == pageSize and page < pageCount then
					selected = 1
					page = page +1
				else
					selected = math.min(selected + 1, recipes.n - pageSize*(page-1))
				end
			elseif event[2] == keys.right and not event[3] then
				page = math.min(page + 1, pageCount or 1)
				selected = math.min(selected, recipes.n - pageSize*(page-1))
			elseif event[2] == keys.left and not event[3] then
				page = math.max(page - 1, 1)
			elseif event[2] == keys.three and not event[3] then
				recipes[recipes[pageSize*(page-1)+selected]] = 3
				saveRecipes()
			elseif event[2] == keys.two and not event[3] then
				recipes[recipes[pageSize*(page-1)+selected]] = 2
				saveRecipes()
			elseif event[2] == keys.one and not event[3] then
				recipes[recipes[pageSize*(page-1)+selected]] = 1
				saveRecipes()
			end
		end
	end
end

local function pullInput()
	local pulled = false
	repeat
		-- compact input chest
		for slot in pairs(inputChest.list()) do
			inputChest.pushItems(inputChest.PERIPHERAL_NAME, slot) -- TODO: peripheral.getName
		end

		if not pairs(turtleChest.list())(turtleChest.list()) then
			for slot, item in pairs(inputChest.list()) do
				local minToPull
				local hasRecipe = false
				if recipes[item.name..":"..item.damage] == 3 then
					minToPull = 9
					hasRecipe = true
				elseif recipes[item.name..":"..item.damage] == 2 then
					minToPull = 4
					hasRecipe = true
				elseif recipes[item.name..":"..item.damage] == nil then
					recipes[item.name..":"..item.damage] = 1
					recipes.n = (recipes.n or 0) + 1
					recipes[recipes.n] = item.name..":"..item.damage
					saveRecipes()
				end
				if hasRecipe and item.count >= minToPull then
					local limit = math.floor(item.count/minToPull)*minToPull
					inputChest.pushItems(turtleChest.PERIPHERAL_NAME, slot, limit) -- TODO: peripheral.getName
					pulled = true
					break
				end
			end
		end
	until pulled
end

local function pullTurtle()
	local total = 0
	local threeXThreeMode = false
	for _, item in pairs(turtleChest.list()) do
		total = total + item.count
		threeXThreeMode = recipes[item.name..":"..item.damage] == 3
	end

	local amountToPull = 1
	local slots
	if threeXThreeMode then
		amountToPull = math.floor(total/9)
		slots = threeXThreeSlots
	else
		amountToPull = math.floor(total/4)
		slots = twoXTwoSlots
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
	for slot, item in pairs(turtleChest.list()) do
		while turtleChest.pushItems(outputChest.PERIPHERAL_NAME, slot) < item.count do end -- TODO: peripheral.getName
	end
end

local function compact()
	-- clean inventory
	-- TODO: fix multi output
	for _, slot in pairs(threeXThreeSlots) do
		turtle.select(slot)
		dropFunc()
	end

	local _,item = pairs(turtleChest.list())(turtleChest.list())
	if item and (not recipes[item.name..":"..item.damage]) then
		pushOutput()
	end

	while true do
		pullTurtle()
		turtle.select(16)
		if turtle.getItemCount(1) > 0 and not turtle.craft() then
			os.queueEvent("compact_error", "Bad inventory, empty turtle chest and turtle then press any key to resume")
			os.pullEvent("compact_resume")
		end
		if turtle.getItemCount(16) > 0 then
			pushOutput()
		end
		pullInput()
	end
end

local function loadRecipes()
	local function unsafeload()
		local file = fs.open(recipeFileName, "r")
		recipes = textutils.unserialize(file.readAll())
		file.close()
		recipes.n = 0
		for k in pairs(recipes) do
			if type(k) == "string" and k ~= "n" then
				recipes.n = recipes.n + 1
				recipes[recipes.n] = k
			end
		end
	end

	if (not fs.exists(recipeFileName)) or fs.isDir(recipeFileName) then
		recipes = {}
		return false, "not a file"
	end

	return pcall(unsafeload)
end

local ok, err = loadRecipes()
if not ok then
	if err ~= "not a file" then
		error("Error loading recipe file: "..err)
	end
end

parallel.waitForAll(doUi, compact)
-- TODO: fix messy term when closing the program
