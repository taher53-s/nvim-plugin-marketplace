local M = {}

local git = require("marketplace.git")
local data = require("marketplace.data")
local logger = require("marketplace.logger")

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
M.category_filter = ""

M.installed = {}
M.lock = {}
M.installing = {}
M.drift_cache = {}

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
-- Filter by search query and category
-------------------------------------------------
function M.filter(items)
	local result = {}

	for _, item in ipairs(items) do
		local matches_query = M.query == "" or item.name:lower():find(M.query:lower(), 1, true)
		local matches_category = M.category_filter == "" or item.category == M.category_filter

		if matches_query and matches_category then
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

	-- Prevent duplicate install
	if M.installing[name] then
		if on_done then
			on_done(false, "Install already in progress")
		end
		logger.warn("Install already in progress for " .. name)
		return
	end

	-- Already installed
	if vim.fn.isdirectory(path) == 1 then
		if on_done then
			on_done(true, "Already installed")
		end
		logger.info(name .. " already installed")
		return
	end

	M.installing[name] = true
	logger.info("Installing " .. name .. "...")

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

			logger.info("Installed " .. name)

			if on_done then
				on_done(true, "Installed successfully")
			end
		else
			logger.error("Install failed for " .. name)

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
	local name = plugin.name
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) == 1 then
		vim.fn.delete(path, "rf")
		logger.info("Uninstalled " .. name)
	else
		logger.warn("Tried to uninstall non-existing plugin: " .. name)
	end

	M.installed[name] = nil
	M.lock[name] = nil

	M.save()
	M.save_lockfile()
end

-------------------------------------------------
-- Update plugin
-------------------------------------------------
function M.update(plugin, on_done)
	local name = plugin.name
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) ~= 1 then
		logger.warn("Update skipped, plugin not installed: " .. name)

		if on_done then
			on_done(false, "Plugin not installed")
		end
		return
	end

	logger.info("Updating " .. name .. "...")

	git.pull(path, function(success)
		if success then
			logger.info("Updated " .. name)

			if on_done then
				on_done(true, "Updated successfully")
			end
		else
			logger.error("Update failed for " .. name)

			if on_done then
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

	for _, installed in pairs(M.installed) do
		if installed then
			total = total + 1
		end
	end

	if total == 0 then
		logger.info("No plugins installed to update")

		if on_done then
			on_done("No plugins installed")
		end
		return
	end

	logger.info("Updating all plugins...")

	for name, installed in pairs(M.installed) do
		if installed then
			local plugin = M.find_plugin_by_name(name)

			if plugin then
				M.update(plugin, function()
					completed = completed + 1

					if completed == total then
						logger.info("All plugins updated")

						if on_done then
							on_done("All plugins updated")
						end
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
		logger.info("Lockfile empty, nothing to restore")

		if on_done then
			on_done()
		end
		return
	end

	logger.info("Restoring plugins from lockfile...")

	for name, commit in pairs(M.lock) do
		local plugin = M.find_plugin_by_name(name)

		if not plugin then
			logger.warn("Plugin definition not found for: " .. name)

			completed = completed + 1
			if completed == total and on_done then
				logger.info("Restore completed")
				on_done()
			end
			goto continue
		end

		local path = M.get_plugin_path(plugin)

		-- If already installed, skip clone but checkout commit
		local function finalize()
			M.installed[name] = true
			M.save()

			completed = completed + 1
			if completed == total then
				logger.info("Restore completed")
				if on_done then
					on_done()
				end
			end
		end

		local function checkout_commit()
			vim.system({ "git", "-C", path, "checkout", commit }, {}, function()
				vim.schedule(function()
					finalize()
				end)
			end)
		end

		if vim.fn.isdirectory(path) == 1 then
			logger.info("Restoring existing plugin: " .. name)
			checkout_commit()
		else
			logger.info("Cloning " .. name .. " for restore")

			git.clone(plugin.repo, path, function(success)
				if success then
					checkout_commit()
				else
					logger.error("Failed to clone during restore: " .. name)

					completed = completed + 1
					if completed == total and on_done then
						logger.info("Restore completed")
						on_done()
					end
				end
			end)
		end

		::continue::
	end
end
-------------------------------------------------
-- Clear drift cache (call on fresh open)
-------------------------------------------------
function M.clear_drift_cache()
	M.drift_cache = {}
end

-------------------------------------------------
-- Check drift with caching
-------------------------------------------------
function M.check_drift_cached(plugin, callback)
	local cached = M.drift_cache[plugin.name]
	if cached then
		callback(cached)
		return
	end

	M.check_drift(plugin, function(status)
		M.drift_cache[plugin.name] = status
		callback(status)
	end)
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
			logger.warn("Drift check failed for " .. plugin.name)
			callback("Missing")
			return
		end

		if current == locked then
			callback("Up to date")
		else
			logger.info("Plugin outdated: " .. plugin.name)
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
		logger.warn("Health check: missing plugin " .. plugin.name)
		callback("Missing (not installed)")
		return
	end

	if vim.fn.isdirectory(path .. "/.git") ~= 1 then
		logger.error("Health check: corrupted repo " .. plugin.name)
		callback("Corrupted (no .git directory)")
		return
	end

	git.get_branch(path, function(success, branch)
		if not success then
			logger.error("Health check git error for " .. plugin.name)
			callback("Git error")
			return
		end

		if branch == "HEAD" then
			logger.warn("Health check: detached HEAD for " .. plugin.name)
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
