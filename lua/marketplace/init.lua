local M = {}

M.config = {
	border = "rounded",
	title = "Plugin  Marketplace",
}

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})
end

function M.open()
	print("🛒 " .. M.config.title)
end

return M
