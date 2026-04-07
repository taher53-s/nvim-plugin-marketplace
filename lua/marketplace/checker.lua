-- Background update checker for plugin drift detection
-- Runs async checks on plugins and caches results

local M = {}

local state = require("marketplace.state")
local logger = require("marketplace.logger")

-------------------------------------------------
-- Background update checker
-------------------------------------------------

-- Tracks running background jobs
M.running = {}

-- Check if background check is already running for a plugin
function M.is_checking(name)
	return M.running[name] == true
end

-- Run background drift check on all installed plugins (non-blocking)
function M.check_all_installed(on_done)
	local installed = {}
	for name in pairs(state.installed) do
		table.insert(installed, name)
	end

	if #installed == 0 then
		logger.info("Background check: no plugins installed")
		if on_done then on_done() end
		return
	end

	logger.info("Background check: scanning " .. #installed .. " plugins...")

	local total = #installed
	local completed = 0

	for _, name in ipairs(installed) do
		local plugin = state.find_plugin_by_name(name)
		if plugin then
			M.check_plugin(plugin, function()
				completed = completed + 1
				if completed == total and on_done then
					logger.info("Background check: complete")
					on_done()
				end
			end)
		else
			completed = completed + 1
		end
	end
end

-- Check a single plugin's drift status in background
function M.check_plugin(plugin, on_done)
	local name = plugin.name

	if M.running[name] then
		if on_done then on_done() end
		return
	end

	M.running[name] = true

	-- Read from cache first if fresh enough (< 5 minutes)
	local cached = state.metadata_cache[name]
	if cached and cached.ts and (vim.loop.now() - cached.ts) < 300000 then
		M.running[name] = nil
		if on_done then on_done() end
		return
	end

	-- Async drift check
	state.check_drift_cached(plugin, function(status)
		M.running[name] = nil

		if status == "Outdated" then
			logger.info("Background: " .. name .. " is outdated")
		end

		if on_done then on_done() end
	end)
end

return M