-- Handles window creation and UI rendering

local M = {}

local buffer = require("marketplace.buffer")
local data = require("marketplace.data")

function M.open(config)
	-- LEFT WINDOW (list)
	local list_buf = vim.api.nvim_create_buf(false, true)

	local width = 40
	local height = 15

	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - (width * 2 + 2)) / 2)

	local list_win = vim.api.nvim_open_win(list_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = config.border,
	})

	-- RIGHT WINDOW (preview)
	local preview_buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_open_win(preview_buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col + width + 2,
		style = "minimal",
		border = config.border,
	})

	-- highlight group
	vim.api.nvim_set_hl(0, "MarketplaceSelected", {
		bg = "#2a2a2a",
		bold = true,
	})

	-- render list and inject preview callback
	buffer.render(list_buf, data.plugins, function(plugin)
		M.render_preview(preview_buf, plugin)
	end)

	vim.api.nvim_win_set_cursor(list_win, { 1, 0 })
end

-- Render preview panel
function M.render_preview(bufnr, plugin)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
		"📦 " .. plugin.name,
		"",
		plugin.desc,
	})

	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

return M
