local fluidPipe = require("fluid_pipe")

local pipe = fluidPipe.newPipe("cookingforblockheads:sink_0") -- this is the source inventory

-- filters and priorities are still a thing, see the item pipe demo for details
-- output filter is filter(fluid, tank)
-- input filter is filter(fluid)
-- fluid is { amount, name }
-- tank is the number id of the tank

pipe.addDestination("powah:thermo_gen_0")

local builtPipe = pipe.build()

while true do
  builtPipe.tick() -- go through the source once attempting to move the items
  sleep(1)
end

