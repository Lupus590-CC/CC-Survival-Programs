local toConvertItems = {
	-- TODO: we way want to know what it shold convert into, could be useful for communicating to a crafting system
	["minecraft:gravel"] = true, -- minecraft:flint
	["minecraft:stone"] = true, -- minecraft:cobblestone
	["minecraft:grass"] = true, -- minecraft:dirt
}

-- code

settings.define("lupus590.block_place_dig_converter.drop_side", {
	description = "The side to output into. [ top | bottom | front ]",
	type = "string",
})

settings.define("lupus590.block_place_dig_converter.suck_side", {
	description = "The side to input from. [ top | bottom | front ]",
	type = "string",
})

settings.define("lupus590.block_place_dig_converter.dig_side", {
	description = "The side to dig. [ top | bottom | front ]",
	type = "string",
})

settings.save()
settings.load()

local dropSide = settings.get("lupus590.block_place_dig_converter.drop_side")
local suckSide = settings.get("lupus590.block_place_dig_converter.suck_side")
local digSide = settings.get("lupus590.block_place_dig_converter.dig_side")

dropSide = dropSide and dropSide:lower()
suckSide = suckSide and suckSide:lower()
digSide = digSide and digSide:lower()

if (not dropSide) or (dropSide ~= "top" and dropSide ~= "bottom" and dropSide ~= "front") then
	error("Drop side is not set, use the set command and set lupus590.block_place_dig_converter.drop_side to a valid side.", 0)
end

if (not suckSide) or (suckSide ~= "top" and suckSide ~= "bottom" and suckSide ~= "front") then
	error("Suck side is not set, use the set command and set lupus590.block_place_dig_converter.suck_side to a valid side.", 0)
end

if (not digSide) or (digSide ~= "top" and digSide ~= "bottom" and digSide ~= "front") then
	error("Dig side is not set, use the set command and set lupus590.block_place_dig_converter.dig_side to a valid side.", 0)
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

local dig = {
	top = turtle.digUp,
	bottom = turtle.digDown,
	front = turtle.dig,
}

local place = {
	top = turtle.placeUp,
	bottom = turtle.placeDown,
	front = turtle.place,
}

local detect = {
	top = turtle.detectUp,
	bottom = turtle.detectDown,
	front = turtle.detect,
}

local suckFunc = suck[suckSide]
local dropFunc = drop[dropSide]
local digFunc = dig[digSide]
local placeFunc = place[digSide]
local detectFunc = detect[digSide]

while true do
	if turtle.getItemCount() == 0 and not detectFunc() then
		suckFunc(1)
	end
	placeFunc()
	digFunc()
	local item = turtle.getItemDetail()
	if item and not toConvertItems[item.name] then
		dropFunc()
	end
end
