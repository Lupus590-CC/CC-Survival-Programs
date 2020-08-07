-- WARNING: this program will not break branches, make sure that your tree will
-- not make branches. you can achieve this by puting your tree in a room with
-- an appropiatly highted roof or by using a tree type which doesn't make
-- branches
local fuel = { ["minecraft:coal"] = true, ["minecraft:lava_bucket"] = true }
local maxWaitTime = 120

local leaves = "minecraft:leaves"
local logs = "minecraft:log"
local saplings = "minecraft:sapling"
local scanner = peripheral.find("plethora:scanner")

local movementStack = {}
do
    local fileLocation = ".movementStack"
    local stack
    do
        local f = fs.open(fileLocation, "r")
        local s = f and f.readAll()
        stack = s and textutils.unserialise(s)
    end
    stack = stack or {n = 0}

    local inverter = {
        ["forward"] = turtle.back,
        ["back"] = turtle.forward,
        ["turnLeft"] = turtle.turnRight,
        ["turnRight"] = turtle.turnLeft,
        ["up"] = turtle.down,
        ["down"] = turtle.up,
    }

    local function saveStack()
        io.open(fileLocation, "w"):write(textutils.serialise(stack)):close()
    end

    function movementStack.pushForward()
        stack.n = stack.n+1
        stack[stack.n] = "forward"
        saveStack()
        return turtle.forward()
    end

    function movementStack.pushBack()
        stack.n = stack.n+1
        stack[stack.n] = "back"
        saveStack()
        return turtle.back()
    end

    function movementStack.pushTurnRight()
        stack.n = stack.n+1
        stack[stack.n] = "turnRight"
        saveStack()
        return turtle.turnRight()
    end

    function movementStack.pushTurnLeft()
        stack.n = stack.n+1
        stack[stack.n] = "TurnLeft"
        saveStack()
        return turtle.TurnLeft()
    end
    function movementStack.pushUp()
        stack.n = stack.n+1
        stack[stack.n] = "up"
        saveStack()
        return turtle.up()
    end

    function movementStack.pushDown()
        stack.n = stack.n+1
        stack[stack.n] = "down"
        saveStack()
        return turtle.down()
    end

    function movementStack.pop() -- TODO: inteligently look several ahead and simplify rotations
        local moveToUndo = stack[stack.n]
        stack[stack.n] = nil
        stack.n = stack.n-1
        --[[if moveToUndo == "turnRight" or moveToUndo == "turnLeft" and stack[stack.n] == moveToUndo and stack[stack.n-1] == moveToUndo and stack[stack.n-2] == moveToUndo then -- doesn't work, makes it go to the wrong place
            stack[stack.n] = nil
            stack[stack.n-1] = nil
            stack[stack.n-2] = nil
            stack.n = stack.n-2
            return movementStack.pop()
        end]]
        local undoFunction = inverter[moveToUndo] --or function() end
        saveStack()
        return undoFunction()
    end

    function movementStack.hasMovements()
        return stack.n > 0
    end
end

local veinMine -- TODO: smartly mine all the leaves - traveling salesman problem algorithm with plethora block scanner
do
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
                movementStack.pushForward()
                veinMine()
                movementStack.pop()
            end
            movementStack.pushTurnRight()
        end
        if isDesireableUp() then
            turtle.digUp()
            movementStack.pushUp()
            veinMine()
            movementStack.pop()
        end
        if isDesireableDown() then
            turtle.digDown()
            movementStack.pushDown()
            veinMine()
            movementStack.pop()
        end
        for i = 1, 4 do
            movementStack.pop()
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

-- TODO: remove the bounce after clearing the leaves

local function clearLeaves()
    veinMine()
    while movementStack.hasMovements() do -- TODO: remove the extra spinning
        movementStack.pop()
        veinMine()
    end
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
    -- TODO: refuel from logs
    -- TODO: fuel chest
    -- TODO: don't dump fuel
    local saplingSlot
    for i = 1, 16 do
        local dumpItems = true
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item and item.name == saplings then
            if saplingSlot then
                turtle.transferTo(saplingSlot)
                turtle.refuel()
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