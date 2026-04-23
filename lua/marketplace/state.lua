local M = {}
local git = require("marketplace.git")
local logger = require("marketplace.logger")

local lockfile_path = vim.fn.stdpath("data") .. "/marketplace-lock.json"
M.install_path = vim.fn.stdpath("data") .. "/marketplace_plugins"

-- Volatile Run-Time State
M.installed = {}
M.lock = {}
M.recommended = {}
M.search_results = {}
M.search_mode = false
M.current_display = {}
M.progress = {}
M.current_index = 1
M.is_loading = false
M.sort_method = ""
M.strict_filter = false
M.last_query = ""

function M.get_plugin_path(plugin)
	return M.install_path .. "/" .. plugin.name
end

function M.ensure_install_dir()
	if vim.fn.isdirectory(M.install_path) == 0 then
		vim.fn.mkdir(M.install_path, "p")
	end
end

function M.load_lockfile()
	local file = io.open(lockfile_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		local ok, decoded = pcall(vim.fn.json_decode, content)
		if ok and type(decoded) == "table" then
			M.lock = decoded
		end
	end
end

function M.save_lockfile()
	local file = io.open(lockfile_path, "w")
	if file then
		file:write(vim.fn.json_encode(M.lock))
		file:close()
	end
end

-- Synchronously detect what's physically on disk
function M.sync_installed_from_filesystem()
	M.ensure_install_dir()
	M.installed = {}
	for _, dir in ipairs(vim.fn.readdir(M.install_path)) do
		local full = M.install_path .. "/" .. dir
		if vim.fn.isdirectory(full) == 1 then
			M.installed[dir] = true
		end
	end
end

function M.is_installed(plugin)
	local path = M.get_plugin_path(plugin)
	return vim.fn.isdirectory(path) == 1
end

function M.install(plugin, on_update)
	M.ensure_install_dir()
	local path = M.get_plugin_path(plugin)

	if vim.fn.isdirectory(path) == 1 then
		if on_update then on_update(nil, "Already configured/installed.") end
		return
	end

	logger.info("Triggered Clone for " .. plugin.name .. "...")
	git.clone(plugin.repo, path, function(percent)
		-- Send live update stream
		if on_update then on_update(percent, "Downloading...") end
	end, function(success)
		if success then
			M.installed[plugin.name] = true
			git.get_commit(path, function(ok, commit)
				if ok then
					-- Register repo and commit for restoration functionality
					M.lock[plugin.name] = { commit = commit, repo = plugin.repo }
					M.save_lockfile()
				end
			end)
			logger.info("Successfully Installed " .. plugin.name)
			if on_update then on_update(nil, "Installed successfully.") end
		else
			logger.error("Failed installing " .. plugin.name)
			if on_update then on_update(nil, "Network or Git Error. Install failed.") end
		end
	end)
end

function M.uninstall(plugin, on_done)
	local path = M.get_plugin_path(plugin)
	if vim.fn.isdirectory(path) == 1 then
		vim.fn.delete(path, "rf")
		M.installed[plugin.name] = nil
		M.lock[plugin.name] = nil
		M.save_lockfile()
		logger.info("Uninstalled " .. plugin.name)
		if on_done then on_done("Uninstalled successfully.") end
	end
end

function M.update(plugin, on_done)
	local path = M.get_plugin_path(plugin)
	if vim.fn.isdirectory(path) ~= 1 then
		if on_done then on_done("Feature Not installed.") end
		return
	end
	
	git.pull(path, function(success)
		if success then
			logger.info("Updated " .. plugin.name)
			if on_done then on_done("Updated flawlessly.") end
		else
			logger.error("Failed Updating " .. plugin.name)
			if on_done then on_done("Update failed.") end
		end
	end)
end

function M.update_all(on_done)
	logger.info("Force updating all local directories.")
	for name in pairs(M.installed) do
		M.update({ name = name }, function() end)
	end
	if on_done then on_done("Mass Update Initialized.") end
end

function M.restore_from_lockfile(on_done)
	M.ensure_install_dir()
	for name, data in pairs(M.lock) do
		local path = M.get_plugin_path({ name = name })
		
		-- If physically missing, clone it securely using embedded lockfile URLs
		if vim.fn.isdirectory(path) ~= 1 and type(data) == "table" and data.repo then
			git.clone(data.repo, path, function(success)
				if success then
					vim.system({"git", "-C", path, "checkout", data.commit})
				end
			end)
		end
	end
	if on_done then on_done("Restore Process Dispatched in background.") end
end

return M
