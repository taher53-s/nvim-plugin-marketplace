local M = {}

local utils = require("marketplace.utils")
local data = require("marketplace.data")

-- File path for persistence
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"

-- Where plugins will be installed
M.install_path = vim.fn.stdpath("data") .. "/marketplace_plugins"

-------------------------------------------------
-- Ensure install directory exists
-------------------------------------------------
function M.ensure_install_dir()
	if vim.fn.isdirectory(M.install_path) == 0 then
		vim.fn.mkdir(M.install_path, "p")
	end
end

-------------------------------------------------
-- Get full path of a plugin
-------------------------------------------------
function M.get_plugin_path(plugin)
	return M.install_path .. "/" .. plugin.name
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

-------------------------------------------------
-- Synchronize installed state from filesystem
-------------------------------------------------
function M.sync_installed_from_filesystem()
	M.ensure_install_dir()

	local dirs = vim.fn.readdir(M.install_path)

	-- Reset installed table
	M.installed = {}

	for _, dir in ipairs(dirs) do
		local full_path = M.install_path .. "/" .. dir

		if vim.fn.isdirectory(full_path) == 1 then
			M.installed[dir] = true
		end
	end

	M.save()
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
-- Find plugin definition by name
-------------------------------------------------
function M.find_plugin_by_name(name)
	for _, plugin in ipairs(data.plugins) do
		if plugin.name == name then
			return plugin
		end
	end
	return nil
end

-------------------------------------------------
-- Install plugin (real git clone)
-------------------------------------------------
function M.install(plugin)
	M.ensure_install_dir()

	local path = M.get_plugin_path(plugin)

	-- Install dependencies first
	if plugin.dependencies then
		for _, dep_name in ipairs(plugin.dependencies) do
			local dep_plugin = M.find_plugin_by_name(dep_name)

			if dep_plugin and not M.is_installed(dep_plugin) then
				print("Installing dependency: " .. dep_name)
				M.install(dep_plugin)
			end
		end
	end

	-- Skip if already installed
	if vim.fn.isdirectory(path) == 1 then
		print(plugin.name .. " already installed")
		return
	end

	print("Installing " .. plugin.name .. "...")

	local cmd = {
		"git",
		"clone",
		"--depth",
		"1",
		plugin.repo,
		path,
	}

	local success, result = utils.run(cmd)

	if success then
		M.installed[plugin.name] = true
		print("Installed " .. plugin.name)
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
	print("Uninstalled " .. plugin.name)
	M.save()
end

-------------------------------------------------
-- Check if plugin is installed (filesystem truth)
-------------------------------------------------
function M.is_installed(plugin)
	local path = M.get_plugin_path(plugin)
	return vim.fn.isdirectory(path) == 1
end

-------------------------------------------------
-- Load installed plugins into runtimepath
-- Prevent duplicate runtimepath entries
-------------------------------------------------
function M.load_installed_plugins()
	for name, _ in pairs(M.installed) do
		local path = M.install_path .. "/" .. name

		if vim.fn.isdirectory(path) == 1 then
			-- Only append if not already in runtimepath
			if not string.find(vim.o.runtimepath, path, 1, true) then
				vim.opt.rtp:append(path)
			end
		end
	end
end

return M
