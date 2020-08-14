local lavaBucket = "minecraft:lava_bucket"


while true do
    local item = turtle.getItemDetail()
    if item and item.name ~= lavaBucket then
        turtle.dropDown()
    end

    turtle.dig()

    item = turtle.getItemDetail()
    if item and item.name ~= lavaBucket then
        turtle.dropDown()
    end

    turtle.suckUp()
    item = turtle.getItemDetail()
    if item and item.name == lavaBucket then
        turtle.place()
    end
end
