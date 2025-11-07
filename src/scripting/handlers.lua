local handlers = { }

-- handlers has two fields
-- `start` and `update`: both functions
-- `start(executionID, ...)` arguments of the command is passed in.
-- `update(executionID, dt, ...)` arguments of the command is passed in.
-- there must be a `start` function,`update` is optional, but it means that `start` always declares the handler as complete
-- `start`, and `update` return one value, `isComplete`




--- handler validation
local keysToRemove = { }
for key, handler in pairs(handlers) do
  if type(handler) ~= "table" then
    logger.warn("Script handler found with non-table value. Removing: "..tostring(key).."'")
    table.insert(keysToRemove, key)
  else
    local updateType = type(handler.update)
    if updateType ~= "function" and updateType ~= "nil" then
      logger.warn("Script handler found update callback that wasn't function or nil. Removing: '"..tostring(key).."'")
      table.insert(keysToRemove, key)
    else
      if type(handler.start) ~= "function" then
        if updateType ~= "function" then
          logger.warn("Script handler found without start callback. Removing: '"..tostring(key).."'")
          table.insert(keysToRemove, key)
        else
          handler.start = function(executionID, ...)
            handler.update(executionID, 0, ...) -- Pass dt as 0,
          end
        end
      end
    end
  end
end
for _, key in ipairs(keysToRemove) do
  handlers[key] = nil
end

return handlers