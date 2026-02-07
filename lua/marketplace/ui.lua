-- Handles window creation and UI rendering

local M = {}

local buffer = require("marketplace.buffer")
local data = require("marketplace.data")

function M.open(config)
	-- create scratch buffer
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- window size
	local width = 50
	local height = 15

	-- center window
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- open floating window
	local win = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = config.border,
	})

	-- highlight group for selected item
	vim.api.nvim_set_hl(0, "MarketplaceSelected", {
		bg = "#2a2a2a",
		bold = true,
	})

	-- render plugin list
	buffer.render(bufnr, data.plugins)

	-- ensure cursor starts at first item
	vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

return M
