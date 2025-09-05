-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/ui/MessageLog.lua

local MessageLog = {
    messages = {},
    maxMessages = 100, -- How many messages to store
    scrollOffset = 0
}

-- Colors for different message types
local colors = {
    default = {0.8, 0.8, 0.8},
    player_attack = {1, 1, 1},
    enemy_attack = {1, 0.5, 0.5},
    kill = {0.5, 1, 0.5}, -- Also used for level up
    info = {1, 1, 0.5}
}

function MessageLog.add(text, colorKey)
    local color = colors[colorKey] or colors.default
    
    -- Add the new message to the top of the list
    table.insert(MessageLog.messages, 1, {text = text, color = color})
    -- If we are scrolled, adding a new message should reset the scroll to show the latest.
    MessageLog.scrollOffset = 0
    
    -- Trim the log if it exceeds the max number of messages to store (e.g., 100)
    if #MessageLog.messages > MessageLog.maxMessages then
        table.remove(MessageLog.messages)
    end
end

function MessageLog.clear()
    MessageLog.messages = {}
    MessageLog.scrollOffset = 0
end

function MessageLog.getMessages()
    local visibleMessages = {}
    for i = 1 + MessageLog.scrollOffset, #MessageLog.messages do
        table.insert(visibleMessages, MessageLog.messages[i])
    end
    return visibleMessages
end

function MessageLog.scroll(direction)
    -- direction should be 1 (down/older) or -1 (up/newer)
    local maxScroll = math.max(0, #MessageLog.messages - 5) -- 5 is number of visible lines
    MessageLog.scrollOffset = math.max(0, math.min(maxScroll, MessageLog.scrollOffset + direction))
end

return MessageLog