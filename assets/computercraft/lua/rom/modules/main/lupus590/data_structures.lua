--- Create a new stack data structure.
---@return table stack The Stack.
local function newStack()
    local stack = {_backingTable = {n=0}}

	--- Test if the stack is empty.
	---@return boolean . True if the stack is empty, false otherwise.
    function stack.isEmpty()
        return stack._backingTable.n == 0
    end

	--- Add an item to the stack.
	---@param value any The item to add.
    function stack.push(value)
        stack._backingTable.n = stack._backingTable.n + 1
        stack._backingTable[stack._backingTable.n] = value
    end

	--- Remove the top most item from the stack.
	---@return any stack The item that was at the top of the stack.
    function stack.pop()
        if stack.isEmpty() then
            error("Stack is empty, can't pop an empty stack.", 2)
        end
        local value = stack._backingTable[stack._backingTable.n]
        stack._backingTable.n = stack._backingTable.n - 1
        return value
    end

	function stack.peek()
        if stack.isEmpty() then
            error("Stack is empty, can't peek an empty stack.", 2)
        end

		return stack._backingTable[stack._backingTable.n]
	end

    return stack
end

--- Create a new queue data structure.
---@return table queue The queue.
local function newQueue()
    local queue = {_backingTable = {head=0, tail = 0}, _maxHeadDrift = 10}

    --- Test if the queue is empty.
    ---@return boolean . True if the queue is empty, false otherwise.
    function queue.isEmpty()
        return (queue._backingTable.tail - queue._backingTable.head) == 0
    end

    --- A helper function that compresses the backing table that represents the queue.
	--- You shouldn't need to call this function yourself.
    function queue._compact()
        if queue.isEmpty() or queue._backingTable.head < queue._maxHeadDrift-1 then return end
        local newPos = 1
        local backingTable = queue._backingTable
        for pos = backingTable.head, backingTable.tail do
            backingTable[newPos] = backingTable[pos]
            newPos = newPos + 1
        end
        backingTable.head = 1
        backingTable.tail = newPos-1
    end

    --- Add an item to the queue.
    ---@param value any The item to add to the queue.
    function queue.enqueue(value)
       queue._backingTable.tail = queue._backingTable.tail + 1
       queue._backingTable[queue._backingTable.tail] = value
    end

    --- Remove an item from the queue.
	---@return any value The item that was at the front of the queue.
    function queue.dequeue()
        if queue.isEmpty() then
            error("Queue is empty, can't dequeue an empty queue.", 2)
        end
        queue._backingTable.head = queue._backingTable.head + 1
        local value = queue._backingTable[queue._backingTable.head]
        queue._compact()
        return value
    end

	function queue.peek()
        if queue.isEmpty() then
            error("Stack is empty, can't peek an empty stack.", 2)
        end

		return queue._backingTable[queue._backingTable.head+1]
	end


    return queue
end

return {
    newStack = newStack,
    newQueue = newQueue,
}
