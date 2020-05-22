local function allFull()
  for i = 1, 16 do
    if turtle.getItemSpace(i) > 0 then
      return false
    end
  end
  return true
end

while true do
  if allFull() then
    print("paused due to full inventory, press any key to resume")
    os.pullEvent("key")
    print("attemting to resume")
  end
  turtle.dig()
end
