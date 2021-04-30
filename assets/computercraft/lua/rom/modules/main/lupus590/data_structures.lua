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
    return stack
end

local function newQueue()
  local queue = {_backingTable = {head=1, tail = 0}, _maxHeadDrift = 10}

  function queue.isEmpty()
      return (queue._backingTable.tail - queue._backingTable.head) == 0
  end

  function queue._compact() -- TODO: fix
      if queue.isEmpty() or queue._backingTable.head < queue._maxHeadDrift then return end
      local newPos = 1
      local backingTable = queue._backingTable
      for pos = backingTable.head, backingTable.tail do
          backingTable[newPos] = backingTable[pos]
          newPos = newPos + 1
      end
      backingTable.head = 0
      backingTable.tail = newPos
  end

  function queue.enqueue(value)
      queue._backingTable.tail = queue._backingTable.tail + 1
      queue._backingTable[queue._backingTable.tail] = value
  end

  function queue.dequeue()
      if queue.isEmpty() then
          error("Queue is empty, can't dequeue an empty queue.", 2)
      end
      --queue._compact() -- TODO: restore
      local value = queue._backingTable[queue._backingTable.head]
      queue._backingTable.head = queue._backingTable.head + 1
      return value
  end
  return queue
end

return {
    newStack = newStack,
    newQueue = newQueue,
}
