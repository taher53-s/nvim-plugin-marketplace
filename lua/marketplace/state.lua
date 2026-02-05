local M = {}

M.current_index = 1

function M.move(delta, max)
  local next_index = M.current_index + delta

  if next_index < 1 then
    next_index = 1
  elseif next_index > max then
    next_index = max
  end

  M.current_index = next_index
end

return M
