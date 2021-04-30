local function newStack()
    local stack = {_backingTable = {n=0}}

    function stack.isEmpty()
        return _backingTable.n == 0
    end

    function stack.push(value)
        stack._backingTable.n = _backingTable.n + 1
        stack._backingTable[_backingTable.n] = value
    end

    function stack.pop()
        if stack.isEmpty() then
            error("Stack is empty, can't pop an empty stack.", 2)
        end
        local value = stack._backingTable[_backingTable.n]
        stack._backingTable.n = _backingTable.n - 1
        return value
    end
end

return {
    newStack = newStack,
}
