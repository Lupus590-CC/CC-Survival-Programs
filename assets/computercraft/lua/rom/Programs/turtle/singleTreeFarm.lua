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

local checkpoint = {}
do
    --[[
    -- @Name: Checkpoint
    -- @Author: Lupus590
    -- @License: MIT
    -- @URL: https://github.com/CC-Hive/Checkpoint
    --
    -- If you are interested in the above format: http://www.computercraft.info/forums2/index.php?/topic/18630-rfc-standard-for-program-metadata-for-graphical-shells-use/
    --
    -- Includes stack tracing code from SquidDev's Mildly Better Shell (Also known as MBS): http://www.computercraft.info/forums2/index.php?/topic/29253-mildly-better-shell-various-extensions-to-the-default-shell/
    --
    -- Checkpoint doesn't save your program's data, it must do that itself. Checkpoint only helps it to get to roughly the right area of code to resume execution.
    --
    -- One may want to have a table with needed data in which gets passed over checkpoints with each checkpoint segment first checking that this table exists and loading it from a file if it doesn't and the last thing it does before reaching the checkpoint is saving this table to that file.
    --
    -- Checkpoint's License:
    --
    --  The MIT License (MIT)
    --
    --  Copyright (c) 2018 Lupus590
    --
    -- Permission is hereby granted, free of charge, to any person obtaining a copy
    -- of this software and associated documentation files (the "Software"), to
    -- deal in the Software without restriction, including without limitation the
    -- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    -- sell copies of the Software, and to permit persons to whom the Software is
    -- furnished to do so, subject to the following conditions: The above copyright
    -- notice and this permission notice shall be included in all copies or
    -- substantial portions of the Software.
    --
    -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    -- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    -- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    -- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    -- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    -- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    -- IN THE SOFTWARE.
    --
    --
    -- MBS's License:
    --
    --  The MIT License (MIT)
    --
    --  Copyright (c) 2017 SquidDev
    --
    --  Permission is hereby granted, free of charge, to any person obtaining a copy
    --  of this software and associated documentation files (the "Software"), to deal
    --  in the Software without restriction, including without limitation the rights
    --  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    --  copies of the Software, and to permit persons to whom the Software is
    --  furnished to do so, subject to the following conditions:
    --
    --  The above copyright notice and this permission notice shall be included in all
    --  copies or substantial portions of the Software.
    --
    --  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    --  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    --  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    --  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    --  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    --  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    --  SOFTWARE.
    --
    --
    --]]

    -- TODO: cleanup code

    -- TODO: use argValidationUtils?
    local function argChecker(position, value, validTypesList, level)
        -- check our own args first, sadly we can't use ourself for this
        if type(position) ~= "number" then
        error("argChecker: arg[1] expected number got "..type(position),2)
        end
        -- value could be anything, it's what the caller wants us to check for them
        if type(validTypesList) ~= "table" then
        error("argChecker: arg[3] expected table got "..type(validTypesList),2)
        end
        if not validTypesList[1] then
        error("argChecker: arg[3] table must contain at least one element",2)
        end
        for k, v in ipairs(validTypesList) do
        if type(v) ~= "string" then
            error("argChecker: arg[3]["..tostring(k).."] expected string got "..type(v),2)
        end
        end
        if type(level) ~= "nil" and type(level) ~= "number" then
        error("argChecker: arg[4] expected number or nil got "..type(level),2)
        end
        level = level and level + 1 or 3

        -- check the client's stuff
        for k, v in ipairs(validTypesList) do
        if type(value) == v then
            return
        end
        end

        local expectedTypes
        if #validTypesList == 1 then
            expectedTypes = validTypesList[1]
        else
            expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList - 1) .. " or " .. validTypesList[#validTypesList]
        end

        error("arg["..tostring(position).."] expected "..expectedTypes
        .." got "..type(value), level)
    end

    local checkpointFile = ".checkpoint"

    local checkpoints = {}

    local checkpointTrace = {}

    local nextLabel

    local useStackTracing = true -- sets default for the API, program can set at runtime with third arg to checkpoint.run

    local intentionalError -- true if traceback function belives the error is intentional, false otherwise, nil if traceback has not be generated

    -- MBS Stack Tracing

    local function traceback(x)
        -- Attempt to detect error() and error("xyz", 0).
        -- This probably means they're erroring the program intentionally and so we
        -- shouldn't display anything.
        if x == nil or (type(x) == "string" and not x:find(":%d+:")) then
        intentionalError = true
        return x
        end

        intentionalError = false
        if type(debug) == "table" and type(debug.traceback) == "function" then
        return debug.traceback(tostring(x), 2)
        else
        local level = 3
        local out = { tostring(x), "stack traceback:" }
        while true do
            local _, msg = pcall(error, "", level)
            if msg == "" then
            break
            end

            out[#out + 1] = "  " .. msg
            level = level + 1
        end

        return table.concat(out, "\n")
        end
    end

    local function trimTraceback(target, marker)
        local ttarget, tmarker = {}, {}
        for line in target:gmatch("([^\n]*)\n?") do
        ttarget[#ttarget + 1] = line
        end
        for line in marker:gmatch("([^\n]*)\n?") do
        tmarker[#tmarker + 1] = line
        end

        local t_len, m_len = #ttarget, #tmarker
        while t_len >= 3 and ttarget[t_len] == tmarker[m_len] do
        table.remove(ttarget, t_len)
        t_len, m_len = t_len - 1, m_len - 1
        end

        return ttarget
    end

    -- ENd of MBS Stack Tracing




    function checkpoint.add(label, callback, ...)
        argChecker(1, label, {"string"})
        argChecker(2, callback, {"function"})

        checkpoints[label] = {callback = callback, args = table.pack(...), }
    end

    function checkpoint.remove(label) -- this is intended for debugging, users can use it to make sure that their programs don't loop on itself when it's not meant to
        argChecker(1, label, {"string"})
        if not checkpoints[label] then
        error("Bad arg[1], no known checkpoint with label "..tostring(label), 2)
        end

        checkpoints[label] = nil
    end

    function checkpoint.reach(label)
        argChecker(1, label, {"string"})
        if not checkpoints[label] then
        error("Bad arg[1], no known checkpoint with label '"..tostring(label)
        .."'. You may want to check spelling, scope and such.", 2)
        end

        local f = fs.open(checkpointFile,"w")
        f.writeLine(label)
        f.close()
        nextLabel = label
    end

    function checkpoint.run(defaultLabel, fileName, stackTracing) -- returns whatever the last callback returns (xpcall stuff stripped if used)
        argChecker(1, defaultLabel, {"string"})
        argChecker(2, fileName, {"string", "nil"})
        argChecker(3, stackTracing, {"boolean", "nil"})
        if not checkpoints[defaultLabel] then
        error("Bad arg[1], no known checkpoint with label "
        ..tostring(defaultLabel), 2)
        end

        if stackTracing ~= nil then
        useStackTracing = stackTracing
        end

        checkpointFile = fileName or checkpointFile
        nextLabel = defaultLabel



        if fs.exists(checkpointFile) then
        local f = fs.open(checkpointFile, "r")
        nextLabel = f.readLine()
        f.close()
        if not checkpoints[nextLabel] then
            error("Found checkpoint file '"..fileName.."' containing unknown label '"
            ..nextLabel.."'. Are your sure that this is the right file "
            .."and that nothing is changing it?", 0)
        end
        end


        local returnValues

        while nextLabel ~= nil do
        local l = nextLabel
        checkpointTrace[#checkpointTrace+1] = nextLabel
        nextLabel = nil

        if useStackTracing then
            -- The following line is horrible, but we need to capture the current traceback and run
            -- the function on the same line.
            intentionalError = nil
            returnValues = table.pack(xpcall(function() return checkpoints[l].callback(table.unpack(checkpoints[l].args, 1, checkpoints[l].args.n)) end, traceback))
            local ok   = table.remove(returnValues, 1)
            if not ok then
            local trace = traceback("checkpoint.lua"..":1:")
            local errorMessage = ""
            if returnValues[1] ~= nil then
                trace = trimTraceback(returnValues[1], trace)

                local max, remaining = 15, 10
                if #trace > max then
                for i = #trace - max, 0, -1 do
                    table.remove(trace, remaining + i)
                end
                table.insert(trace, remaining, "  ...")
                end

                errorMessage = table.concat(trace, "\n")

                if intentionalError == false and errorMessage ~= "Terminated" then
                errorMessage = errorMessage
                .."\n\nCheckpoints ran in this instance:\n  "
                ..table.concat(checkpointTrace, "\n  ").." <- error occured in\n"
                end
            end

            error(errorMessage, 0)
            end -- if not ok
        else
            returnValues = table.pack(checkpoints[l].callback(table.unpack(checkpoints[l].args, 1, checkpoints[l].args.n)))
        end

        end

        -- we have finished the program, delete the checkpointFile so that the program starts from the beginning if ran again
        if fs.exists(checkpointFile) then
        fs.delete(checkpointFile)
        end
        return table.unpack(returnValues, 1, returnValues.n)
    end
end

local lama
do
    --[[ The MIT License (MIT)

    -- Copyright (c) 2015 KingofGamesYami

    -- Permission is hereby granted, free of charge, to any person obtaining a copy
    -- of this software and associated documentation files (the "Software"), to
    -- deal in the Software without restriction, including without limitation the
    -- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    -- sell copies of the Software, and to permit persons to whom the Software is
    -- furnished to do so, subject to the following conditions: The above copyright
    -- notice and this permission notice shall be included in all copies or
    -- substantial portions of the Software.
    --
    -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    -- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    -- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    -- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    -- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    -- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    -- IN THE SOFTWARE.
    --]]

    -- Converted to be Require compatible by Lupus590 and released under the same MIT license.
    -- Look for REQUIRE_COMPAT in comments, the connected multi line comments are removed original stuff with the replacement under that.

    -- TODO: copy to hive (I think I fixed the require compatablility)

    -- TODO: reference frames? may need a full rewrite
    -- how to track reference frames?
    -- how to access reference frames?
    -- push/pop interface for creating and removing reference frames
    -- don't forget to use argValidationUtils

    -- REQUIRE_COMPAT

    --Copy the default turtle directory
    local turtle = {}
    for k, v in pairs( _G.turtle ) do
        turtle[ k ] = v
    end

    --copy default gps
    local gps = {}
    for k, v in pairs( _G.gps ) do
        gps[ k ] = v
    end

    if not fs.isDir( ".lama" ) then
        fs.makeDir( ".lama" )
    end

    -- REQUIRE_COMPAT
    lama = {}

    local fuel = {}
    local facing = {}
    local position = {}

    --Fuel tracking
    fuel.load = function() --loading fuel data
        if fs.exists( ".lama/fuel" ) then --if we've got previous data, we want to use it
        local file = fs.open( ".lama/fuel", "r" )
        fuel.amount = tonumber( file.readAll() )
        file.close()
        else --otherwise, use the current fuel level
        fuel.amount = turtle.getFuelLevel()
        end
    end

    fuel.save = function() --save fuel data
        local file = fs.open( ".lama/fuel", "w" )
        file.write( fuel.amount )
        file.close()
    end

    --facing tracking
    facing.turnRight = function() --changes the facing clockwise (on a compass) once
        if facing.face == "north" then
        facing.face = "east"
        elseif facing.face == "east" then
        facing.face = "south"
        elseif facing.face == "south" then
        facing.face = "west"
        elseif facing.face == "west" then
        facing.face = "north"
        end
    end

    facing.save = function() --saves facing and current movement direction
        local file = fs.open( ".lama/facing", "w" )
        file.write( textutils.serialize( {facing.face, facing.direction} ) )
        file.close()
    end

    facing.load = function() --loads facing / current movement direction
        if fs.exists( ".lama/facing" ) then --if we have previous data, we use it
        local file = fs.open( ".lama/facing", "r" )
        facing.face, facing.direction = unpack( textutils.unserialize( file.readAll() ) )
        file.close()
        else --otherwise, try to locate via gps
        local x, y, z = gps.locate(1)
        if x and turtle.forward() then
            local newx, newy, newz = gps.locate(1)
            if not newx then --we didn't get a location
            facing.face = "north" --default
            elseif newx > x then
            facing.face = "east"
            elseif newx < x then
            facing.face = "west"
            elseif newz > z then
            facing.face = "south"
            elseif newz < z then
            facing.face = "north"
            end
        else
            facing.face = "north" --we couldn't move forward, something was obstructing
        end
        end
    end

    --position tracking
    position.save = function() --saves position (x, y, z)
        position.update() --update the position based on direction and fuel level, then save it to a file
        local file = fs.open( ".lama/position", "w" )
        file.write( textutils.serialize( { position.x, position.y, position.z } ) )
        file.close()
    end

    position.load = function() --loads position (x, y z)
        if fs.exists( ".lama/position" ) then --if we have previous data, use it
        local file = fs.open( ".lama/position", "r" )
        position.x, position.y, position.z = unpack( textutils.unserialize( file.readAll() ) )
        file.close()
        else --otherwise try for gps coords
        local x, y, z = gps.locate(1)
        if x then
            position.x, position.y, position.z = x, y, z
        else --now we assume 1,1,1
            position.x, position.y, position.z = 1, 1, 1
        end
        end
    end

    position.update = function() --updates the position of the turtle
        local diff = fuel.amount - turtle.getFuelLevel()
        if diff > 0 then --if we've spent fuel (ei moved), we'll need to move that number in a direction
        if facing.direction == 'east' then
            position.x = position.x + diff
        elseif facing.direction == "west" then
            position.x = position.x - diff
        elseif facing.direction == "south" then
            position.z = position.z + diff
        elseif facing.direction == "north" then
            position.z = position.z - diff
        elseif facing.direction == "up" then
            position.y = position.y + diff
        elseif facing.direction == "down" then
            position.y = position.y - diff
        end
        end
        fuel.amount = turtle.getFuelLevel() --update the fuel amount
        fuel.save() --save the fuel amount
    end

    --direct opposite compass values, mainly for env.back
    local opposite = {
        ["north"] = "south",
        ["south"] = "north",
        ["east"] = "west",
        ["west"] = "east",
    }

    lama.forward = function() --basically, turtle.forward
        if facing.direction ~= facing.face then --if we were going a different direction before
        position.save() --save out position
        facing.direction = facing.face --update the direction
        facing.save() --save the direction
        end
        return turtle.forward() --go forward, return result
    end

    lama.back = function() --same as lama.forward, but going backwards
        if facing.direction ~= opposite[ facing.face ] then
        position.save()
        facing.direction = opposite[ facing.face ]
        facing.save()
        end
        return turtle.back()
    end

    lama.up = function() --turtle.up
        if facing.direction ~= "up" then --if we were going a different direction
        position.save() --save our position
        facing.direction = "up" --set the direction to up
        facing.save() --save the direction
        end
        return turtle.up() --go up, return result
    end

    lama.down = function() --lama.up, but for going down
        if facing.direction ~= "down" then
        position.save()
        facing.direction = "down"
        facing.save()
        end
        return turtle.down()
    end

    lama.turnRight = function() --turtle.turnRight
        position.save() --save the position (x,y,z)
        facing.turnRight() --update our compass direction
        facing.save() --save it
        return turtle.turnRight() --return the result
    end

    lama.turnLeft = function() --lama.turnRight, but the other direction
        position.save()
        facing.turnRight() --going clockwise 3 times is the same as
        facing.turnRight() --going counterclockwise once
        facing.turnRight()
        facing.save()
        return turtle.turnLeft()
    end

    lama.refuel = function( n ) --needed because we depend on fuel level
        position.update() --update our position
        if turtle.refuel( n ) then --if we refueled then
        fuel.amount = turtle.getFuelLevel() --set our amount to the current level
        fuel.save() --save that amount
        return true
        end
        return false --otherwise, return false
    end

    lama.overwrite = function( t ) --writes lama values into the table given
        t = t or _G.turtle    --or, if no value was given, _G.turtle
        for k, v in pairs( lama ) do
        t[ k ] = v
        end
    end

    lama.getPosition = function() --returns the current position of the turtle
        position.update() --first we should update the position (otherwise it'll give coords of the last time we did this)
        return position.x, position.y, position.z, facing.face
    end

    lama.setPosition = function( x, y, z, face ) --sets the current position of the turtle
        position.x = x
        position.y = y
        position.z = z
        facing.face = face or facing.face --default the the current facing if it's not provided
        position.save() --save our new position
        facing.save() --save the way we are facing
    end

    --overwrite gps.locate
    _G.gps.locate = function( n, b )
        local x, y, z, facing = lama.getPosition()
        return x, y, z
    end

    facing.load()
    position.load()
    fuel.load()

    fuel.save()
    position.save()
    facing.save()
end

local function waitForTree()
    local sleepTime = 0
    local _, blockData = turtle.inspect()
    while not (blockData and blockData.name == logs) do
      sleepTime = math.min(sleepTime + math.floor(sleepTime/2) +1, maxWaitTime)
      os.sleep(sleepTime)
      _, blockData = turtle.inspect()
    end
    checkpoint.reach("climbTreeFirst")
end
checkpoint.add("waitForTree", waitForTree)

local function climbTree(chopWoodNext)
    local _, blockData = turtle.inspect()
    while blockData and blockData.name == logs and turtle.up() do
        _, blockData = turtle.inspect()
    end
    while ((not blockData) or blockData.name ~= logs) and turtle.down() do
        _, blockData = turtle.inspect()
    end
    if chopWoodNext then
        checkpoint.reach("chopWood")
    else
        checkpoint.reach("clearLeaves")
    end
end
checkpoint.add("climbTreeFirst", climbTree)
checkpoint.add("climbTreeSecond", climbTree, true)

local function clearLeaves()
    veinMine()
    -- TODO: return to tree trunk
    -- TODO: percistance support
    -- stack based movement tracking, serialize to file?
    checkpoint.reach("climbTreeSecond")
end
checkpoint.add("clearLeaves", clearLeaves)

local function chopWood()
    climbTree(true)
    local _, blockData = turtle.inspect()
    while blockData and blockData.name == logs do
        turtle.dig()
        turtle.down()
        _, blockData = turtle.inspect()
    end
    checkpoint.reach("plantSapling")
end
checkpoint.add("chopWood", chopWood)

local function plantSapling()
    for i = 1, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item and item.name == saplings then
            turtle.place()
            break
        end
    end
    checkpoint.reach("offLoadItems")
end
checkpoint.add("plantSapling", plantSapling)

local function offLoadItems()
    local saplingSlot
    for i = 1, 16 do
        local dumpItems = true
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item and item.name == saplings then
            if saplingSlot then
                turtle.transferTo(saplingSlot)
            else
                saplingSlot = i
                dumpItems = false
            end
        end
        while dumpItems and turtle.getItemCount() > 0 do
            turtle.dropDown()
        end
    end
    checkpoint.reach("waitForTree")
end
checkpoint.add("offLoadItems", offLoadItems)

checkpoint.run("waitForTree")