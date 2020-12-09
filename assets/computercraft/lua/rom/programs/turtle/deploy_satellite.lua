-- TODO: return garantee for chunk unloads
-- TODO: place multiple computers with appropriate GPS

while turtle.up() do
end

turtle.select(1)
turtle.down()
turtle.placeUp()

turtle.down()
turtle.select(2)
turtle.placeUp()

turtle.back()
turtle.up()
turtle.up()
peripheral.call("front", "turnOn")
turtle.down()
turtle.down()
turtle.forward()

while turtle.down() do
end
