local M = {}

M.installing = {}
M.lock = {}

local utils = require("marketplace.utils")
local data = require("marketplace.data")
local lockfile_path = vim.fn.stdpath("data") .. "/marketplace-lock.json"

-- File path for persistence
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"

-- Where plugins will be installed
M.install_path = vim.fn.stdpath("data") .. "/marketplace_plugins"

-------------------------------------------------
-- Save lockfile (plugin commit hashes)
-------------------------------------------------
function M.save_lockfile()
	local json = vim.fn.json_encode(M.lock)

	local file = io.open(lockfile_path, "w")
	if file then
		file:write(json)
		file:close()
	end
end

-------------------------------------------------
-- Load lockfile
-------------------------------------------------
function M.load_lockfile()
	local file = io.open(lockfile_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.lock = decoded
	end
end

-------------------------------------------------
-- Get current installed commit hash
-------------------------------------------------
function M.get_current_commit(plugin, callback)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) ~= 1 then
		callback(nil)
		return
	end

	local cmd = {
		"git",
		"-C",
		path,
		"rev-parse",
		"HEAD",
	}

	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			if success then
				callback(vim.trim(output))
			else
				callback(nil)
			end
		end)
	end)
end

-------------------------------------------------
-- Check if plugin is out of sync with lockfile
-------------------------------------------------
function M.check_drift(plugin, callback)
	local locked_commit = M.lock[plugin.name]

	if not locked_commit then
		callback("Untracked")
		return
	end

	M.get_current_commit(plugin, function(current_commit)
		if not current_commit then
			callback("Missing")
			return
		end

		if current_commit == locked_commit then
			callback("Up to date")
		else
			callback("Outdated")
		end
	end)
end

-------------------------------------------------
-- Restore all plugins from lockfile
-------------------------------------------------
function M.restore_from_lockfile(on_done)
	M.ensure_install_dir()

	local total = 0
	local completed = 0

	for name, commit in pairs(M.lock) do
		total = total + 1

		local plugin = M.find_plugin_by_name(name)
		if plugin then
			local path = M.get_plugin_path(plugin)

			-- Clone fresh
			local clone_cmd = {
				"git",
				"clone",
				plugin.repo,
				path,
			}

			utils.run_async(clone_cmd, function(success, _)
				vim.schedule(function()
					if success then
						-- Checkout exact commit
						local checkout_cmd = {
							"git",
							"-C",
							path,
							"checkout",
							commit,
						}

						utils.run_async(checkout_cmd, function(_, _)
							vim.schedule(function()
								M.installed[name] = true
								M.save()

								completed = completed + 1
								if completed == total and on_done then
									on_done()
								end
							end)
						end)
					else
						completed = completed + 1
						if completed == total and on_done then
							on_done()
						end
					end
				end)
			end)
		end
	end
end

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
function M.install(plugin, on_done)
	M.ensure_install_dir()

	local name = plugin.name
	local path = M.get_plugin_path(plugin)

	-- Prevent duplicate install
	if M.installing[name] then
		if on_done then
			on_done(false, "Install already in progress")
		end
		return
	end

	-- Skip if already installed
	if vim.fn.isdirectory(path) == 1 then
		if on_done then
			on_done(true, "Already installed")
		end
		return
	end

	-- Mark as installing
	M.installing[name] = true

	local cmd = {
		"git",
		"clone",
		"--depth",
		"1",
		plugin.repo,
		path,
	}

	utils.run_async(cmd, function(success, result)
		vim.schedule(function()
			-- Clear installing flag
			M.installing[name] = nil

			if success then
				-- Get current commit hash
				local hash_cmd = {
					"git",
					"-C",
					path,
					"rev-parse",
					"HEAD",
				}

				utils.run_async(hash_cmd, function(hash_success, hash_output)
					vim.schedule(function()
						if hash_success then
							local commit = vim.trim(hash_output)
							M.lock[name] = commit
							M.save_lockfile()
						end
					end)
				end)
				if on_done then
					on_done(true, "Installed successfully")
				end
			else
				if on_done then
					on_done(false, "Install failed")
				end
			end
		end)
	end)
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
-- Update plugin (git pull)
-------------------------------------------------
function M.update(plugin)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) ~= 1 then
		print(plugin.name .. " is not installed")
		return false, "Plugin not installed"
	end

	print("Updating " .. plugin.name .. "...")

	local cmd = {
		"git",
		"-C",
		path,
		"pull",
	}

	local success, result = utils.run(cmd)

	if success then
		print("Updated " .. plugin.name)
		return true, "Update successful"
	else
		print("Update failed:")
		print(result)
		return false, result
	end
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
