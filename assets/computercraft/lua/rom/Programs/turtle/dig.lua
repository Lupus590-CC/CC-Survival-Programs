
local completion = require("cc.shell.completion")

shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
    { completion.choice, { "down", "up", "forward" } }
))

local dir = ...
if dir and type(dir) ~= "string" then
  error("bad arg", 0)
end
dir = dir and dir:lower() or nil
if dir == "d" or dir == "down" then
  turtle.digDown()
elseif dir == "u" or dir == "up" then
  turtle.digUp()
elseif dir == nil or dir == "f" or dir == "forwards" or dir == "forward" then
  turtle.dig()
elseif dir == "addshellcomplete" then
  return
else
  error("bad arg", 0)
end
