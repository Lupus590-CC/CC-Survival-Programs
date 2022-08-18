local virtualPipes = require("lupus590.virtual_pipes")

local pipe = virtualPipes.newFluidPipe()

pipe.AddSource("cookingforblockheads:sink_0") -- this is the source inventory

-- filters and priorities are still a thing, see the item pipe demo for details
-- output filter is filter(fluid, tank)
-- input filter is filter(fluid)
-- fluid is { amount, name }
-- tank is the number id of the tank
-- See the item pipe demo for more info

pipe.addDestination("powah:thermo_gen_0")

local builtPipe = pipe.build()

while true do
    builtPipe.tick() -- go through each source once attempting to move the fluids
    sleep(1)
end

