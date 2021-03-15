
if not turtle.dig then
	error("Requires turtle that can dig, a mining turtle is best.", 0)
end

if not shell.complete(shell.getRunningProgram().." ") then
	local completion = require("cc.shell.completion")

	shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
			{ completion.choice, { "down ", "up", "forward" } },
			{ completion.choice, { "veinMine", "noVeinMine" } }
	))
end

local function printUsage()
	local programName = arg[0] or fs.getName(shell.getRunningProgram())
	print("Usage: " .. programName .. " down [ veinMine | noVeinMine ]")
	print("Usage: " .. programName .. " up [ veinMine | noVeinMine ]")
	print("Usage: " .. programName .. " forward [ veinMine | noVeinMine ]")
	print("Usage: " .. programName .. " addShellComplete")
end

local arg = arg or table.pack(...)
if #arg == 0 or #arg > 2 or arg[1]:lower() == "help" then
	printUsage()
	return
end

local desireables = {}
local veinMine
do
	local function isDesireable()
		local ok, item = turtle.inspect()
		return ok and desireables[item.name]
	end
	local function isDesireableUp()
		local ok, item = turtle.inspectUp()
		return ok and desireables[item.name]
	end
	local function isDesireableDown()
		local ok, item = turtle.inspectDown()
		return ok and desireables[item.name]
	end

	function veinMine()
		for i = 1, 4 do
			if isDesireable() then
				turtle.dig()
				turtle.forward()
				veinMine()
				turtle.back()
			end
			turtle.turnRight()
		end
		if isDesireableUp() then
			turtle.digUp()
			turtle.up()
			veinMine()
			turtle.down()
		end
		if isDesireableDown() then
			turtle.digDown()
			turtle.down()
			veinMine()
			turtle.up()
		end
	end
end

local doVeinMine =  arg[2] and arg[2]:lower() or nil
if doVeinMine == "veinmine" or doVeinMine == "v" then
	doVeinMine = true
elseif doVeinMine == "noveinmine" or doVeinMine == nil then
	doVeinMine = false
else
	printUsage()
	return
end

local function startVeinMine(block)
	desireables[block.name] = true
	veinMine()
end


local dir = arg[1] and arg[1]:lower() or nil
if dir == "d" or dir == "down" then
	if doVeinMine then
		local _, block = turtle.inspectDown()
		startVeinMine(block)
	else
		turtle.digDown()
	end
elseif dir == "u" or dir == "up" then
	if doVeinMine then
		local _, block = turtle.inspectUp()
		startVeinMine(block)
	else
		turtle.digUp()
	end
elseif dir == nil or dir == "" or dir == "f" or dir == "forwards" or dir == "forward" then
	if doVeinMine then
		local _, block = turtle.inspect()
		startVeinMine(block)
	else
		turtle.dig()
	end
elseif dir == "addshellcomplete" then
	return
else
	printUsage()
	return
end
