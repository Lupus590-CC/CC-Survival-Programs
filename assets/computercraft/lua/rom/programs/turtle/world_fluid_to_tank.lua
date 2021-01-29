settings.define("lupus590.world_fluid_to_tank.fluid_side", {
    description = "The side of the fluid source in the world. [ up | down | front ]",
    type = "string",
})

settings.define("lupus590.world_fluid_to_tank.fluid_loader_side", {
    description = "The side of the fluid loader. [ up | down | front ]",
    type = "string",
})

settings.save()
settings.load()

local fluidSide = settings.get("lupus590.world_fluid_to_tank.fluid_side")
local fluidLoaderSide = settings.get("lupus590.world_fluid_to_tank.fluid_loader_side")

fluidSide = fluidSide and fluidSide:lower()
fluidLoaderSide = fluidLoaderSide and fluidLoaderSide:lower()

if (not fluidSide) or (fluidSide ~= "up" and fluidSide ~= "down" and fluidSide ~= "front") then
    error("Fluid side is not set, use the set command and set lupus590.world_fluid_to_tank.fluid_side to a valid side.", 0)
end

if (not fluidLoaderSide) or (fluidLoaderSide ~= "up" and fluidLoaderSide ~= "down" and fluidLoaderSide ~= "front") then
    error("Fluid loader side is not set, use the set command and set lupus590.world_fluid_to_tank.fluid_loader_side to a valid side.", 0)
end

local suck = {
    up = turtle.suckUp,
    down = turtle.suckDown,
    front = turtle.suck,
}

local drop = {
    up = turtle.dropUp,
    down = turtle.dropDown,
    front = turtle.drop,
}

local place = {
    up = turtle.placeUp,
    down = turtle.placeDown,
    front = turtle.place,
}

local placeFunc = place[fluidSide]
local dropFunc = drop[fluidLoaderSide]
local suckFunc = suck[fluidLoaderSide]

while true do
    local item = turtle.getItemDetail()
    if item and item.name == "minecraft:bucket" then
        placeFunc()
    end
    item = turtle.getItemDetail()
    if item and item.name == "minecraft:water_bucket" then
        dropFunc()
    end
    sleep(1)
    suckFunc()
end