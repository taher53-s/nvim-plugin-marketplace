-- Main public module for the marketplace plugin
-- Acts as a bridge between command and UI

local M = {}

local ui = require("marketplace.ui")
local state = require("marketplace.state")
local data = require("marketplace.data")

M.config = {
	border = "rounded",
	title = "Plugin Marketplace",
	-- Default plugin settings per name
	plugin_settings = {},
}

-- Merge user-provided plugin settings into plugin_configs
local function apply_plugin_settings()
	for name, settings in pairs(M.config.plugin_settings) do
		if data.plugin_configs[name] then
			data.plugin_configs[name] = vim.tbl_extend("force", data.plugin_configs[name], settings)
		end
	end
end

-- Validate plugin configuration entries
local function validate_plugin_config(name, config, errors)
	errors = errors or {}

	if config.lazy ~= nil and type(config.lazy) ~= "boolean" then
		table.insert(errors, name .. ".lazy must be boolean")
	end

	if config.priority ~= nil and type(config.priority) ~= "number" then
		table.insert(errors, name .. ".priority must be number")
	end

	if config.load_event then
		if type(config.load_event) ~= "table" then
			table.insert(errors, name .. ".load_event must be table")
		elseif type(config.load_event.event) ~= "string" or config.load_event.event == "" then
			table.insert(errors, name .. ".load_event.event must be non-empty string")
		end
	end

	if config.dependencies then
		if type(config.dependencies) ~= "table" then
			table.insert(errors, name .. ".dependencies must be table")
		else
			for i, dep in ipairs(config.dependencies) do
				if type(dep) ~= "string" or dep == "" then
					table.insert(errors, name .. ".dependencies[" .. i .. "] must be non-empty string")
				end
			end
		end
	end

	return errors
end

-- Validate full config before applying
local function validate_config()
	local errors = {}

	for name, config in pairs(M.config.plugin_settings) do
		if not data.plugin_configs[name] then
			table.insert(errors, "Unknown plugin in plugin_settings: " .. name)
		else
			validate_plugin_config(name, config, errors)
		end
	end

	return errors
end

-- Allow user configuration (future-proofing)
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Validate config before applying
	local errors = validate_config()
	if #errors > 0 then
		error("Marketplace config validation failed:\n  " .. table.concat(errors, "\n  "))
	end

	-- Apply user plugin settings (e.g. custom priority, lazy flag)
	apply_plugin_settings()

	-- Load essential state synchronously (fast)
	state.load()
	state.load_lockfile()
	state.sync_lockfile()
	state.load_filters()
	state.load_drift_cache()
	state.load_metadata_cache()

	-- Defer heavy filesystem scan and rtp loading (async, non-blocking)
	vim.defer_fn(function()
		state.sync_installed_from_filesystem()
		state.load_installed_plugins()
		logger.info("Marketplace runtime loaded")
	end, 50)
end

-- Entry point called by :Marketplace
function M.open()
	ui.open(M.config)
end

return M
