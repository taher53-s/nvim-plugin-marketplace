-- Main public module for the marketplace plugin
-- Acts as a bridge between command and UI

local M = {}

local ui = require("marketplace.ui")

M.config = {
	border = "rounded",
	title = "Plugin Marketplace",
}

-- Allow user configuration (future-proofing)
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})
end

-- Entry point called by :Marketplace
function M.open()
	ui.open(M.config)
end

return M
