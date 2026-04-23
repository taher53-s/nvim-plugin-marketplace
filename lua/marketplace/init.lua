local M = {}
local ui = require("marketplace.ui")

M.config = {
	border = "rounded",
}

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})
end

function M.open()
	ui.open(M.config)
end

return M
