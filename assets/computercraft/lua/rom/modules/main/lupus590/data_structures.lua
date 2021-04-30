local function newStack()
    local stack = {_backingTable = {n=0}}

    function stack.isEmpty()
        return stack._backingTable.n == 0
    end

    function stack.push(value)
        stack._backingTable.n = stack._backingTable.n + 1
        stack._backingTable[stack._backingTable.n] = value
    end

    function stack.pop()
        if stack.isEmpty() then
            error("Stack is empty, can't pop an empty stack.", 2)
        end
        local value = stack._backingTable[stack._backingTable.n]
        stack._backingTable.n = stack._backingTable.n - 1
        return value
    end
end

local function newQueue()
    local queue = {_backingTable = {n=0}}

    function queue.isEmpty()
        return queue._backingTable.n == 0
    end

    function queue.enqueue(value)
        queue._backingTable.n = queue._backingTable.n + 1
        queue._backingTable[queue._backingTable.n] = value
    end

    function stack.dequeue()
        if queue.isEmpty() then
            error("Queue is empty, can't dequeue an empty queue.", 2)
        end
        local value = queue._backingTable[queue._backingTable.n]
        queue._backingTable.n = queue._backingTable.n - 1
        return value
    end
end

return {
    newStack = newStack,
    newQueue = newQueue,
}
