local M = {}

function M.create(lines)
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- buffer content
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- buffer options
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

	return bufnr
end

return M
