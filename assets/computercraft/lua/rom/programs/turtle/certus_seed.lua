settings.define("lupus590.certus_seed.water_side", {
  description = "The side that has water to place seeds into. [ top | bottom | front ]",
  type = "string",
})

settings.define("lupus590.certus_seed.input_chest_side", {
  description = "The side to input crystal seeds from. [ top | bottom | front ]",
  type = "string",
})

settings.define("lupus590.certus_seed.output_chest_side", {
  description = "The side to output grown crystals into. [ top | bottom | front ]",
  type = "string",
})

settings.define("lupus590.certus_seed.wait_time", {
  description = "How long to wait (in seconds) before picking crystals up again.",
  type = "number",
  default = 120, -- TODO: find a good default
})

settings.save()
settings.load()

local waterSide = settings.get("lupus590.certus_seed.water_side")
local inputSide = settings.get("lupus590.certus_seed.input_chest_side")
local outputSide = settings.get("lupus590.certus_seed.output_chest_side")

waterSide = waterSide and waterSide:lower()
inputSide = inputSide and inputSide:lower()

if (not waterSide) or (waterSide ~= "top" and waterSide ~= "bottom" and waterSide ~= "front") then
  error("Water side is not set, use the set command and set lupus590.certus_seed.water_side to a valid side.", 0)
end

if (not inputSide) or (inputSide ~= "top" and inputSide ~= "bottom" and inputSide ~= "front") then
  error("Input chest side is not set, use the set command and set lupus590.certus_seed.input_chest_side to a valid side.", 0)
end

if (not outputSide) or (outputSide ~= "top" and outputSide ~= "bottom" and outputSide ~= "front") then
  error("Output chest side is not set, use the set command and set lupus590.certus_seed.output_chest_side to a valid side.", 0)
end

local drop = {
  top = turtle.dropUp,
  bottom = turtle.dropDown,
  front = turtle.drop,
}

local suck = {
  top = turtle.suckUp,
  bottom = turtle.suckDown,
  front = turtle.suck,
}

local suckInputFunc = suck[inputSide]
local dropOutputFunc = drop[outputSide]
local dropWaterFunc = drop[waterSide]
local suckWaterFunc = suck[waterSide]
local waitTime = settings.get("lupus590.certus_seed.wait_time")

local growingName = "appliedenergistics2:crystal_seed"

while true do
  while suckWaterFunc() do end
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and item.name == growingName then
      turtle.select(i)
      dropWaterFunc()
    elseif item then
      turtle.select(i)
      dropOutputFunc()
    end
  end
  while suckInputFunc() do
    dropWaterFunc()
  end
  sleep(waitTime)
end
