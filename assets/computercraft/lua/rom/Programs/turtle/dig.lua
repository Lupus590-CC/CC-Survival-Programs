local dir = ...
if dir and type(dir) ~= "string" then
  error("bad arg")
end
dir = dir and dir:lower() or nil
if dir == "d" or dir == "down" then
  turtle.digDown()
elseif dir == "u" or dir == "up" then
  turtle.digUp()
elseif dir == nil or dir == "f" or dir == "forwards" or dir == "forward" then
  turtle.dig()
else
  error("bad arg")
end
