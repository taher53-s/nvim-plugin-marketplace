local M = {}

local git = require("marketplace.git")
local data = require("marketplace.data")
local logger = require("marketplace.logger")

-------------------------------------------------
-- Paths
-------------------------------------------------
local data_path = vim.fn.stdpath("data") .. "/marketplace.json"
local lockfile_path = vim.fn.stdpath("data") .. "/marketplace-lock.json"
local drift_cache_path = vim.fn.stdpath("data") .. "/marketplace-drift-cache.json"
local filter_path = vim.fn.stdpath("data") .. "/marketplace-filters.json"
local metadata_cache_path = vim.fn.stdpath("data") .. "/marketplace-metadata-cache.json"

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
M.disabled = {}  -- Track disabled plugins
M.metadata_cache = {}  -- Cached plugin metadata (stars, desc, etc.)

-------------------------------------------------
-- Post-install hooks registry
-------------------------------------------------
M.hooks = {
	after_install = {},
	after_uninstall = {},
}

function M.register_hook(event, name, fn)
	if M.hooks[event] then
		M.hooks[event][name] = fn
	end
end

function M.unregister_hook(event, name)
	if M.hooks[event] then
		M.hooks[event][name] = nil
	end
end

function M.run_hooks(event, ...)
	if M.hooks[event] then
		for _, fn in pairs(M.hooks[event]) do
			fn(...)
		end
	end
end

-------------------------------------------------
-- Enable/disable plugin toggle
-------------------------------------------------
function M.is_disabled(plugin)
	return M.disabled[plugin.name] == true
end

function M.disable_plugin(plugin)
	M.disabled[plugin.name] = true
	logger.info("Disabled " .. plugin.name)
end

function M.enable_plugin(plugin)
	M.disabled[plugin.name] = nil
	logger.info("Enabled " .. plugin.name)
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

	-- Load metadata cache for cached plugin info
	M.load_metadata_cache()
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
-- Persist and restore filter state across sessions
-------------------------------------------------

function M.save_filters()
	local file = io.open(filter_path, "w")
	if file then
		file:write(vim.fn.json_encode({
			query = M.query,
			category_filter = M.category_filter,
		}))
		file:close()
	end
end

function M.load_filters()
	local file = io.open(filter_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.query = decoded.query or ""
		M.category_filter = decoded.category_filter or ""
	end
end

-------------------------------------------------
-- Persist drift cache to disk
-------------------------------------------------
function M.save_drift_cache()
	local file = io.open(drift_cache_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.drift_cache))
		file:close()
	end
end

-------------------------------------------------
-- Load drift cache from disk
-------------------------------------------------
function M.load_drift_cache()
	local file = io.open(drift_cache_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.drift_cache = decoded
	end
end

-------------------------------------------------
-- Persist metadata cache to disk (stars, desc, etc.)
-------------------------------------------------
function M.save_metadata_cache()
	local file = io.open(metadata_cache_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.metadata_cache))
		file:close()
	end
end

-------------------------------------------------
-- Load metadata cache from disk
-------------------------------------------------
function M.load_metadata_cache()
	local file = io.open(metadata_cache_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.metadata_cache = decoded
	end
end

-------------------------------------------------
-- Persist filter state across sessions
-------------------------------------------------
function M.save_filters()
	local file = io.open(filter_path, "w")
	if file then
		file:write(vim.fn.json_encode({
			query = M.query,
			category_filter = M.category_filter,
		}))
		file:close()
	end
end

-------------------------------------------------
-- Load filter state from previous session
-------------------------------------------------
function M.load_filters()
	local file = io.open(filter_path, "r")
	if not file then
		return
	end

	local content = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if ok and type(decoded) == "table" then
		M.query = decoded.query or ""
		M.category_filter = decoded.category_filter or ""
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
-- Build dependency graph from all plugin configs
-------------------------------------------------
function M.build_dependency_graph()
	local graph = {}
	for name, config in pairs(data.plugin_configs) do
		graph[name] = config.dependencies or {}
	end
	return graph
end

-------------------------------------------------
-- Async install queue (limit concurrent installs)
-------------------------------------------------
local install_queue = {}
local install_running = 0
local install_concurrency = 2  -- max concurrent installs

local function process_install_queue()
	if #install_queue == 0 or install_running >= install_concurrency then
		return
	end

	local task = table.remove(install_queue, 1)
	install_running = install_running + 1

	task.fn(function(...)
		install_running = install_running - 1
		if task.cb then task.cb(...) end
		process_install_queue()
	end)
end

function M.enqueue_install(fn, callback)
	table.insert(install_queue, { fn = fn, cb = callback })
	process_install_queue()
end

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
			M.run_hooks("after_install", plugin)

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
-- Collect all dependencies for a plugin (recursive, with cycle detection)
-------------------------------------------------
function M.collect_dependencies(name, collected, visiting)
	collected = collected or {}
	visiting = visiting or {}

	if collected[name] or visiting[name] then
		return
	end

	visiting[name] = true

	local config = data.plugin_configs[name]
	if config and config.dependencies then
		for _, dep in ipairs(config.dependencies) do
			M.collect_dependencies(dep, collected, visiting)
		end
	end

	collected[name] = true
	visiting[name] = nil
end

-------------------------------------------------
-- Install plugin with all dependencies
-------------------------------------------------
function M.install_with_deps(plugin, on_done)
	local collected = {}
	M.collect_dependencies(plugin.name, collected)

	-- Remove self, we only want deps
	collected[plugin.name] = nil

	-- Build ordered list: deps first (sorted by name for determinism)
	local dep_list = {}
	for dep_name in pairs(collected) do
		table.insert(dep_list, dep_name)
	end
	table.sort(dep_list)

	local to_install = {}
	for _, dep_name in ipairs(dep_list) do
		local dep_plugin = M.find_plugin_by_name(dep_name)
		if dep_plugin and not M.is_installed(dep_plugin) then
			table.insert(to_install, dep_plugin)
		end
	end

	if #to_install == 0 then
		-- No deps to install, just install self
		M.install(plugin, on_done)
		return
	end

	local total = #to_install + 1
	local completed = 0

	local function check_done(success, msg)
		completed = completed + 1
		if completed == total and on_done then
			on_done(success, msg)
		end
	end

	-- Install deps first
	for _, dep in ipairs(to_install) do
		M.install(dep, function(ok)
			check_done(true, "Installed with dependencies")
		end)
	end

	-- Then install main plugin
	M.install(plugin, function(ok, msg)
		check_done(ok, msg or "Installed successfully")
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
		M.run_hooks("after_uninstall", plugin)
	else
		logger.warn("Tried to uninstall non-existing plugin: " .. name)
	end

	M.installed[name] = nil
	M.lock[name] = nil
	M.drift_cache[name] = nil

	M.save()
	M.save_lockfile()
	M.save_drift_cache()
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
	os.remove(drift_cache_path)
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
		M.save_drift_cache()
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
-- Runtimepath loading with priority-based order
-------------------------------------------------
function M.load_installed_plugins()
	-- Collect all installed plugins with their priorities
	local to_load = {}
	for name, _ in pairs(M.installed) do
		local path = M.install_path .. "/" .. name
		if vim.fn.isdirectory(path) == 1 then
			local config = data.plugin_configs[name]
			local priority = config and config.priority or 50
			table.insert(to_load, { name = name, path = path, config = config, priority = priority })
		end
	end

	-- Sort by priority (lower = loaded first)
	table.sort(to_load, function(a, b)
		return a.priority < b.priority
	end)

	-- Load in priority order
	for _, item in ipairs(to_load) do
		local config = item.config
		local path = item.path

		if config and config.lazy then
			local event = config.load_event
			if event and event.event then
				vim.api.nvim_create_autocmd(event.event, {
					pattern = { "*" },
					once = true,
					callback = function()
						if not string.find(vim.o.runtimepath, path, 1, true) then
							vim.opt.rtp:append(path)
						end
					end,
					desc = "Lazy load " .. item.name .. " on " .. event.event,
				})
			end
		else
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

function M.is_enabled(plugin)
	return M.is_installed(plugin) and not M.is_disabled(plugin)
end

return M
