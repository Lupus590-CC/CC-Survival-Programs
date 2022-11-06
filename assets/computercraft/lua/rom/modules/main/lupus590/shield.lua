--[[
  Shield by AlexDevs
  Protect a function from terminating by wrapping it.

  Usage: shield(function[, ...args])
  Example: local input = shield(read, "*")

  taken from: https://devbin.dev/nnROifdr

  (c) 2021 AlexDevs

  The MIT License
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local expect = require("cc.expect").expect

local function shield(func, ...)
    expect(1, func, "function")

    local thread = coroutine.create(func)

    local event, filter, pars = table.pack(...)
    while coroutine.status(thread) ~= "dead" do
        if event[1] ~= "terminate" and filter == nil or filter == event[1] then
            pars = table.pack(coroutine.resume(thread, table.unpack(event, 1, event.n)))
            if pars[1] then
                filter = pars[2]
            else
                error(pars[2], 0)
            end
        end
        event = table.pack(coroutine.yield())
    end

    return table.unpack(pars, 2)
end

return { shield = shield }
