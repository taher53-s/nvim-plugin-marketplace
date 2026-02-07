-- Responsible for rendering the list buffer
-- Handles navigation, highlighting, and selection

local M = {}

local state = require("marketplace.state")

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace("marketplace")

-- Render plugin list
-- on_select is a callback provided by UI layer
function M.render(bufnr, items, on_select)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	-- build list lines
	local lines = {}
	for i, item in ipairs(items) do
		table.insert(lines, i .. ". " .. item.name)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- reset selection
	state.current_index = 1
	M.highlight(bufnr)

	-- j → move down + update preview
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
		on_select(items[state.current_index])
	end, { buffer = bufnr })

	-- k → move up + update preview
	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
		on_select(items[state.current_index])
	end, { buffer = bufnr })

	-- Enter → call UI-provided callback
	vim.keymap.set("n", "<CR>", function()
		local plugin = items[state.current_index]
		on_select(plugin)
	end, { buffer = bufnr })
end

-- Highlight selected line
function M.highlight(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", state.current_index - 1, 0, -1)
end

return M
