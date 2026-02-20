local M = {}

local git = require("marketplace.git")
local data = require("marketplace.data")

-------------------------------------------------
-- Paths
-------------------------------------------------
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"
local lockfile_path = vim.fn.stdpath("data") .. "/marketplace-lock.json"

M.install_path = vim.fn.stdpath("data") .. "/marketplace_plugins"

-------------------------------------------------
-- Runtime State
-------------------------------------------------
M.current_index = 1
M.query = ""

M.installed = {}
M.lock = {}
M.installing = {}

-------------------------------------------------
-- Ensure install directory exists
-------------------------------------------------
function M.ensure_install_dir()
	if vim.fn.isdirectory(M.install_path) == 0 then
		vim.fn.mkdir(M.install_path, "p")
	end
end

-------------------------------------------------
-- Get plugin path
-------------------------------------------------
function M.get_plugin_path(plugin)
	return M.install_path .. "/" .. plugin.name
end

-------------------------------------------------
-- Save installed plugins
-------------------------------------------------
function M.save()
	local file = io.open(data_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.installed))
		file:close()
	end
end

-------------------------------------------------
-- Load installed plugins
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
-- Save lockfile
-------------------------------------------------
function M.save_lockfile()
	local file = io.open(lockfile_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.lock))
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
-- Sync installed state from filesystem
-------------------------------------------------
function M.sync_installed_from_filesystem()
	M.ensure_install_dir()

	M.installed = {}

	for _, dir in ipairs(vim.fn.readdir(M.install_path)) do
		local full = M.install_path .. "/" .. dir
		if vim.fn.isdirectory(full) == 1 then
			M.installed[dir] = true
		end
	end

	M.save()
end

-------------------------------------------------
-- Find plugin by name
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
-- Filter by search query
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
	end
	if next_index > max then
		next_index = max
	end
	M.current_index = next_index
end

-------------------------------------------------
-- Install plugin (async)
-------------------------------------------------
function M.install(plugin, on_done)
	M.ensure_install_dir()

	local name = plugin.name
	local path = M.get_plugin_path(plugin)

	if M.installing[name] then
		if on_done then
			on_done(false, "Install already in progress")
		end
		return
	end

	if vim.fn.isdirectory(path) == 1 then
		if on_done then
			on_done(true, "Already installed")
		end
		return
	end

	M.installing[name] = true

	git.clone(plugin.repo, path, function(success)
		M.installing[name] = nil

		if success then
			M.installed[name] = true
			M.save()

			-- Capture commit for lockfile
			git.get_commit(path, function(hash_ok, commit)
				if hash_ok then
					M.lock[name] = commit
					M.save_lockfile()
				end
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
	M.lock[plugin.name] = nil

	M.save()
	M.save_lockfile()
end

-------------------------------------------------
-- Update plugin
-------------------------------------------------
function M.update(plugin, on_done)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) ~= 1 then
		if on_done then
			on_done(false, "Plugin not installed")
		end
		return
	end

	git.pull(path, function(success)
		if on_done then
			if success then
				on_done(true, "Updated successfully")
			else
				on_done(false, "Update failed")
			end
		end
	end)
end

-------------------------------------------------
-- Update all installed plugins
-------------------------------------------------
function M.update_all(on_done)
	local total = 0
	local completed = 0

	for name, installed in pairs(M.installed) do
		if installed then
			total = total + 1
		end
	end

	if total == 0 then
		if on_done then
			on_done("No plugins installed")
		end
		return
	end

	for name, installed in pairs(M.installed) do
		if installed then
			local plugin = M.find_plugin_by_name(name)
			if plugin then
				M.update(plugin, function()
					completed = completed + 1
					if completed == total and on_done then
						on_done("All plugins updated")
					end
				end)
			end
		end
	end
end

-------------------------------------------------
-- Restore from lockfile
-------------------------------------------------
function M.restore_from_lockfile(on_done)
	M.ensure_install_dir()

	local total = 0
	local completed = 0

	for _ in pairs(M.lock) do
		total = total + 1
	end
	if total == 0 then
		if on_done then
			on_done()
		end
		return
	end

	for name, commit in pairs(M.lock) do
		local plugin = M.find_plugin_by_name(name)
		if plugin then
			local path = M.get_plugin_path(plugin)

			git.clone(plugin.repo, path, function(success)
				if success then
					vim.system({ "git", "-C", path, "checkout", commit }, {}, function()
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
				end
			end)
		end
	end
end

-------------------------------------------------
-- Drift detection
-------------------------------------------------
function M.check_drift(plugin, callback)
	local locked = M.lock[plugin.name]

	if not locked then
		callback("Untracked")
		return
	end

	local path = M.get_plugin_path(plugin)

	git.get_commit(path, function(success, current)
		if not success then
			callback("Missing")
			return
		end

		if current == locked then
			callback("Up to date")
		else
			callback("Outdated")
		end
	end)
end

-------------------------------------------------
-- Health check
-------------------------------------------------
function M.health_check(plugin, callback)
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) ~= 1 then
		callback("Missing (not installed)")
		return
	end

	if vim.fn.isdirectory(path .. "/.git") ~= 1 then
		callback("Corrupted (no .git directory)")
		return
	end

	git.get_branch(path, function(success, branch)
		if not success then
			callback("Git error")
			return
		end

		if branch == "HEAD" then
			callback("Detached HEAD")
		else
			callback("Healthy (" .. branch .. ")")
		end
	end)
end

-------------------------------------------------
-- Runtimepath loading
-------------------------------------------------
function M.load_installed_plugins()
	for name, _ in pairs(M.installed) do
		local path = M.install_path .. "/" .. name

		if vim.fn.isdirectory(path) == 1 then
			if not string.find(vim.o.runtimepath, path, 1, true) then
				vim.opt.rtp:append(path)
			end
		end
	end
end

-------------------------------------------------
-- Check if plugin is installed (filesystem truth)
-------------------------------------------------
function M.is_installed(plugin)
	local path = M.get_plugin_path(plugin)
	return vim.fn.isdirectory(path) == 1
end

return M
