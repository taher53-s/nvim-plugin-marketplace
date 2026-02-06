-- Responsible for rendering the list buffer
-- Handles keymaps and highlighting

local M = {}

local state = require("marketplace.state")

-- Namespace for highlights (Neovim feature)
local ns = vim.api.nvim_create_namespace("marketplace")

-- Render plugin list into a buffer
function M.render(bufnr, items)
	-- allow writing to buffer
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

	-- write each plugin as a line
	for i, item in ipairs(items) do
		vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
			i .. ". " .. item.name,
		})
	end

	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- reset selection
	state.current_index = 1
	M.highlight(bufnr)

	-- key: j → move down
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
	end, { buffer = bufnr })

	-- key: k → move up
	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)
	end, { buffer = bufnr })
end

-- Highlight the currently selected line
function M.highlight(bufnr)
	-- clear old highlights
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	-- highlight selected line
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", state.current_index - 1, 0, -1)
end

return M
