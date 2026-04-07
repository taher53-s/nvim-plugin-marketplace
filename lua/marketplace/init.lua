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

-- Allow user configuration (future-proofing)
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Apply user plugin settings (e.g. custom priority, lazy flag)
	apply_plugin_settings()

	state.load()
	state.load_lockfile()
	state.sync_installed_from_filesystem()
	state.load_installed_plugins()
end

-- Entry point called by :Marketplace
function M.open()
	ui.open(M.config)
end

return M
