-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/EventSystem.lua
-- A simple global event dispatcher.

local EventSystem = {
    listeners = {}
}

-- Subscribe to an event
-- Example: EventSystem.on("enemyDied", function(enemy) print(enemy.name .. " died!") end)
function EventSystem.on(eventName, callback)
    if not EventSystem.listeners[eventName] then
        EventSystem.listeners[eventName] = {}
    end
    table.insert(EventSystem.listeners[eventName], callback)
end

-- Trigger an event, calling all subscribed callbacks
function EventSystem.trigger(eventName, ...)
    if EventSystem.listeners[eventName] then
        for _, callback in ipairs(EventSystem.listeners[eventName]) do
            callback(...)
        end
    end
end

return EventSystem