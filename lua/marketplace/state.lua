local M = {}

-- File path for persistence
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"
M.install_path = vim.fn.stdpath("data") .. "/marketplace_plugins"

function M.ensure_install_dir()
	if vim.fn.isdirectory(M.install_path) == 0 then
		vim.fn.mkdir(M.install_path, "p")
	end
end

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

--------rm -rf ~/.config/nvim/.git
-----------------------------------------
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
	M.ensure_install_dir()

	local path = M.get_plugin_path(plugin)

	-- Do not reinstall if already exists
	if vim.fn.isdirectory(path) == 1 then
		return
	end

	local cmd = {
		"git",
		"clone",
		plugin.repo,
		path,
	}

	local result = vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		M.installed[plugin.name] = true
		M.save()
	else
		print("Git clone failed:")
		print(result)
	end
end
-------------------------------------------------
-- Uninstall plugin
-------------------------------------------------
function M.uninstall(plugin)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) == 1 then
		vim.fn.delete(path, "rf")
	end

	M.installed[plugin.name] = nil
	M.save()
end

-------------------------------------------------
-- Check if plugin is installed (filesystem truth)
-------------------------------------------------
function M.is_installed(plugin)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) == 1 then
		return true
	end

	return false
end

-------------------------------------------------
-- Load installed plugins into runtimepath
-------------------------------------------------
function M.load_installed_plugins()
	for name, installed in pairs(M.installed) do
		if installed then
			local path = M.install_path .. "/" .. name

			if vim.fn.isdirectory(path) == 1 then
				vim.opt.rtp:append(path)
			end
		end
	end
end

return M
