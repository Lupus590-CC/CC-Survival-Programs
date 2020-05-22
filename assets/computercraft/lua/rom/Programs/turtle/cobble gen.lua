local function allFull()
  for i = 1, 16 do
    if turtle.getItemSpace(i) > 0 then
      return false
    end
  end
  return true
end

while true do
  while allFull() do
    print("paused due to full inventory, remove blocks to resume")
    os.pullEvent("turtle_inventory")
    print("detecked inventory change, attemting to resume")
  end
  turtle.dig()
end
