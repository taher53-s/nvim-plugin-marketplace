-- Main public module for the marketplace plugin
-- Acts as a bridge between command and UI

local M = {}

local ui = require("marketplace.ui")
local state = require("marketplace.state")

M.config = {
	border = "rounded",
	title = "Plugin Marketplace",
}

-- Allow user configuration (future-proofing)
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

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
