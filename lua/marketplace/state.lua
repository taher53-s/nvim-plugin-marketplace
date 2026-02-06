-- This file stores shared state for the marketplace
-- Right now, it only tracks which item is selected

local M = {}

-- Index of the currently selected plugin (1-based)
M.current_index = 1

-- Move selection up or down
-- delta: +1 (down) or -1 (up)
-- max: total number of items
function M.move(delta, max)
	local next_index = M.current_index + delta

	-- prevent going above first item
	if next_index < 1 then
		next_index = 1
	end

	-- prevent going below last item
	if next_index > max then
		next_index = max
	end

	M.current_index = next_index
end

return M
