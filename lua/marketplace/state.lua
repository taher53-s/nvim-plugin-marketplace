local M = {}

M.current_index = 1
M.query = ""

-- Track installed plugins by name
M.installed = {}

-------------------------------------------------
-- Filter items by search query
-------------------------------------------------
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

-------------------------------------------------
-- Move selection safely
-------------------------------------------------
function M.move(delta, max)
	local next_index = M.current_index + delta

	if next_index < 1 then
		next_index = 1
	elseif next_index > max then
		next_index = max
	end

	M.current_index = next_index
end

-------------------------------------------------
-- Install plugin
-------------------------------------------------
function M.install(plugin)
	M.installed[plugin.name] = true
end

-------------------------------------------------
-- Uninstall plugin
-------------------------------------------------
function M.uninstall(plugin)
	M.installed[plugin.name] = nil
end

-------------------------------------------------
-- Check if installed
-------------------------------------------------
function M.is_installed(plugin)
	return M.installed[plugin.name] == true
end

return M
