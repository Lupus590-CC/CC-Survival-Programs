-- WARNING: this program will not break branches, make sure that your tree will
-- not make branches. you can achieve this by puting your tree in a room with
-- an appropiatly highted roof or by using a tree type which doesn't make
-- branches
local fuel = { ["minecraft:coal:0"] = true, ["minecraft:coal:1"] = true, ["minecraft:lava_bucket:0"] = true }
local maxWaitTime = 120

local leaves = "minecraft:leaves"
local logs = "minecraft:log"
local saplings = "minecraft:sapling"
local scanner = peripheral.wrap("plethora:scanner")

local veinMine -- TODO: smartly mine all the leaves - traveling salesman problem algorithm with plethora block scanner
do
    local desireables = leaves

    local function isDesireable()
        local ok, item = turtle.inspect()
        return ok and item.name == leaves
    end
    local function isDesireableUp()
        local ok, item = turtle.inspectUp()
        return ok and item.name == leaves
    end
    local function isDesireableDown()
        local ok, item = turtle.inspectDown()
        return ok and item.name == leaves
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

local function waitForTree()
    local sleepTime = 0
    local _, blockData = turtle.inspect()
    while not (blockData and blockData.name == logs) do
      sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
      os.sleep(sleepTime)
      _, blockData = turtle.inspect()
    end
end

local function climbTree()
    local _, blockData = turtle.inspect()
    while blockData and blockData.name == logs and turtle.up() do
        _, blockData = turtle.inspect()
    end
    while ((not blockData) or blockData.name ~= logs) and turtle.down() do
        _, blockData = turtle.inspect()
    end
end

local function clearLeaves()
    veinMine()
    -- TODO: return to tree trunk
end

local function chopWood()
    local _, blockData = turtle.inspect()
    while blockData and blockData.name == logs do
        turtle.dig()
        turtle.down()
        _, blockData = turtle.inspect()
    end
end

local function plantSapling()
    for i = 1, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item and item.name == saplings then
            turtle.place()
            break
        end
    end
end

local function offloadItems()
    for i = 1, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.dropDown()
        end
    end
end

while true do
    waitForTree()
    climbTree()
    clearLeaves()
    climbTree()
    chopWood()
    plantSapling()
    offloadItems()
end