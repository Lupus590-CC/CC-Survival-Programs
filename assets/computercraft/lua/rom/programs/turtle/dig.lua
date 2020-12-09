
if not shell.complete(shell.getRunningProgram().." ") then
  local completion = require("cc.shell.completion")

  shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
      { completion.choice, { "down", "up", "forward" } }
  ))
end

local function printUsage()
  local programName = arg[0] or fs.getName(shell.getRunningProgram())
  print("Usage: " .. programName .. " down")
  print("Usage: " .. programName .. " up")
  print("Usage: " .. programName .. " forward")
  print("Usage: " .. programName .. " addShellComplete")
end

local arg = arg or table.pack(...)
if #arg ~= 1 then
  printUsage()
  return
end



local dir = arg[1] and arg[1]:lower() or nil
if dir == "d" or dir == "down" then
  turtle.digDown()
elseif dir == "u" or dir == "up" then
  turtle.digUp()
elseif dir == nil or dir == "" or dir == "f" or dir == "forwards" or dir == "forward" then
  turtle.dig()
elseif dir == "addshellcomplete" then
  return
else
  printUsage()
  return
end
