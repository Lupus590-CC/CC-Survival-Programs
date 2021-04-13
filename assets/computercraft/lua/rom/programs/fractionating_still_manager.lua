-- thermal expantion fractional still and pyrolyzer management program

local fluidPipe = require("lupus590.fluid_pipe")
local itemPipe = require("lupus590.item_pipe")

local blockFilter = function() return false end

local fluids = {
    creosoteOil = "thermal:creosote",
    heavyOil = "thermal:heavy_oil",
    lightOil = "thermal:light_oil",
    refinedFuel = "thermal:refined_fuel",
    crudeOil = "thermal:crude_oil",
    sap = "",
    syrup = "",
    resin = "thermal:resin",
    treeOil = "thermal:tree_oil",
}

local tanks = {
    creosoteOil = {
        name = "cyclic:cask_13",
        inFilter = function(fluid) return fluid.name == fluids.creosoteOil end,
        stillFilter = blockFilter,
    },
    heavyOil = {
        name = "cyclic:cask_14",
        inFilter = function(fluid) return fluid.name == fluids.heavyOil end,
        stillFilter = function(fluid, tank) if fluid.count and fluid.count > 100 then return true, 100 end end,
    }, -- 100
    lightOil = {
        name = "cyclic:cask_15",
        inFilter = function(fluid) return fluid.name == fluids.lightOil end,
        stillFilter = function(fluid, tank) if fluid.count and fluid.count > 100 then return true, 100 end end,
    }, -- 100
    refinedFuel = {
        name = "cyclic:cask_16",
        inFilter = function(fluid) return fluid.name == fluids.refinedFuel end,
        stillFilter = blockFilter,
    },
    crudeOil = {
        name = "cyclic:cask_17",
        inFilter = function(fluid) return fluid.name == fluids.crudeOil end,
        stillFilter = function(fluid, tank) if fluid.count and fluid.count > 100 then return true, 100 end end,
    }, -- 100
    sap = {
        name = "cyclic:cask_18",
        inFilter = function(fluid) return fluid.name == fluids.sap end,
        stillFilter = function(fluid, tank) if fluid.count and fluid.count > 1000 then return true, 1000 end end,
    }, -- 1000
    syrup = {
        name = "cyclic:cask_19",
        inFilter = function(fluid) return fluid.name == fluids.syrup end,
        stillFilter = blockFilter,
    },
    resin = {
        name = "cyclic:cask_20",
        inFilter = function(fluid) return fluid.name == fluids.resin end,
        stillFilter = function(fluid, tank) if fluid.count and fluid.count > 200 then return true, 200 end end,
    }, -- 200
    treeOil = {
        name = "cyclic:cask_21",
        inFilter = function(fluid) return fluid.name == fluids.treeOil end,
        stillFilter = blockFilter,
    },
}

local inputTankName = "cyclic:cask_22"
local fractionalStillName = "thermal:machine_refinery_0"
local pyrolyzerName = "thermal:machine_pyrolyzer_0"

local pipes = {}
local fractionalStillPipe = fluidPipe.newPipe(fractionalStillName)
local pyrolyzerPipe = fluidPipe.newPipe(pyrolyzerName)
local inputPipe = fluidPipe.newPipe(inputTankName)

local fractionalStillItemPipe = itemPipe.newPipe(fractionalStillName)
local pyrolyzerItemPipe = itemPipe.newPipe(pyrolyzerName)

peripheral.find("storagedrawers:fractional_drawers_3", function(name)
    fractionalStillItemPipe.addDestination(name)
    pyrolyzerItemPipe.addDestination(name)
end)


local builtFractionalStillItemPipe = fractionalStillItemPipe.build()
local builtPyrolyzeritemPipe = pyrolyzerItemPipe.build()

local function unknownFluidPrinter(fluid, tank)
    for _, knownFluids in pairs(fluids) do
        if knownFluids == fluid.name then
            return true
        end
    end
    print(fluid.name)
    return false
end

fractionalStillPipe.setFilter(unknownFluidPrinter)
pyrolyzerPipe.setFilter(unknownFluidPrinter)
inputPipe.setFilter(unknownFluidPrinter)

for name, tank in pairs(tanks) do
    local pipe = fluidPipe.newPipe(tank.name)
    pipe.addDestination(fractionalStillName).setFilter(tank.stillFilter)
    pipes[name] = pipe.build()

    fractionalStillPipe.addDestination(tank.name).setFilter(tank.inFilter)
    pyrolyzerPipe.addDestination(tank.name).setFilter(tank.inFilter)
    inputPipe.addDestination(tank.name).setFilter(tank.inFilter)
end

local builtFractionalStillPipe = fractionalStillPipe.build()
local builtPyrolyzerPipe = pyrolyzerPipe.build()
local builtInputPipe = inputPipe.build()

while true do
    for _, pipe in pairs(pipes) do
        pipe.tick()
    end
    builtPyrolyzerPipe.tick()
    builtFractionalStillPipe.tick()
    builtInputPipe.tick()
    builtPyrolyzeritemPipe.tick()
    builtFractionalStillItemPipe.tick()

    sleep(30)
end
