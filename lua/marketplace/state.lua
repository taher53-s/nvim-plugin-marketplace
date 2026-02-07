-- Stores shared state for marketplace UI

local M = {}

-- index of selected item
M.current_index = 1

-- current search query
M.query = ""

-- filter items based on query
function M.filter(items)
	if M.query == "" then
		return items
	end

	local result = {}
	local q = M.query:lower()

	for _, item in ipairs(items) do
		if item.name:lower():find(q, 1, true) then
			table.insert(result, item)
		end
	end

	return result
end

-- move selection safely
function M.move(delta, max)
	local next_index = M.current_index + delta

	if next_index < 1 then
		next_index = 1
	end

	if next_index > max then
		next_index = max
	end

	M.current_index = next_index
end

return M
