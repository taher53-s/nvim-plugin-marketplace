local M = {}

-- File path for persistence
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"

M.current_index = 1
M.query = ""
M.installed = {}

-------------------------------------------------
-- Save installed plugins to disk
-------------------------------------------------
function M.save()
	local json = vim.fn.json_encode(M.installed)

	local file = io.open(data_path, "w")
	if file then
		file:write(json)
		file:close()
	end
end

-------------------------------------------------
-- Load installed plugins from disk
-------------------------------------------------
function M.load()
	local file = io.open(data_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.installed = decoded
	end
end

-------------------------------------------------
-- Filter items based on search
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
	M.save()
end

-------------------------------------------------
-- Uninstall plugin
-------------------------------------------------
function M.uninstall(plugin)
	M.installed[plugin.name] = nil
	M.save()
end

-------------------------------------------------
-- Check install state
-------------------------------------------------
function M.is_installed(plugin)
	return M.installed[plugin.name] == true
end

return M
