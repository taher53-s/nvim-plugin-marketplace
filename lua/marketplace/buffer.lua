-- Responsible for rendering the list buffer
-- Handles keymaps and highlighting

local M = {}

local state = require("marketplace.state")

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace("marketplace")

-- Render plugin list into a buffer
function M.render(bufnr, items)
	-- make buffer editable
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	-- build all lines first (IMPORTANT)
	local lines = {}
	for i, item in ipairs(items) do
		table.insert(lines, i .. ". " .. item.name)
	end

	-- replace entire buffer content at once
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- lock buffer
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- reset selection
	state.current_index = 1
	M.highlight(bufnr)

	-- j → move down
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
	end, { buffer = bufnr })

	-- k → move up
	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
	end, { buffer = bufnr })
end

-- Highlight the currently selected line
function M.highlight(bufnr)
	-- clear previous highlight
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	-- apply highlight to selected line
	vim.api.nvim_buf_add_highlight(
		bufnr,
		ns,
		"MarketplaceSelected",
		state.current_index - 1, -- buffer is 0-based
		0,
		-1
	)
end

return M
