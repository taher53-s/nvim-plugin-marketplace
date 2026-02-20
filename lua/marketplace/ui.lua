-- Handles window creation and UI rendering

local M = {}

local buffer = require("marketplace.buffer")
local data = require("marketplace.data")
local state = require("marketplace.state")

function M.open(config)
	state.load()
	-- LEFT WINDOW (list)
	local list_buf = vim.api.nvim_create_buf(false, true)

	-- make it a scratch UI buffer
	vim.api.nvim_buf_set_option(list_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(list_buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(list_buf, "swapfile", false)
	vim.api.nvim_buf_set_option(list_buf, "modifiable", false)

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

	local preview_win = vim.api.nvim_open_win(preview_buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col + width + 2,
		style = "minimal",
		border = config.border,
	})

	-- Close marketplace with q
	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(list_win) then
			vim.api.nvim_win_close(list_win, true)
		end
		if vim.api.nvim_win_is_valid(preview_win) then
			vim.api.nvim_win_close(preview_win, true)
		end
	end, { buffer = list_buf })

	-----------------------------------------------------------------
	-- Highlight Groups
	-----------------------------------------------------------------
	vim.api.nvim_set_hl(0, "MarketplaceSelected", {
		bg = "#2a2a2a",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "MarketplaceTitle", {
		bold = true,
	})

	vim.api.nvim_set_hl(0, "MarketplaceFooter", {
		fg = "#777777",
	})
	vim.api.nvim_set_hl(0, "MarketplaceInstalled", {
		fg = "#6ab04c",
	})

	-----------------------------------------------------------------
	-- Render list
	-----------------------------------------------------------------
	buffer.render(list_buf, data.plugins, function(plugin)
		if plugin then
			M.render_preview(preview_buf, plugin)
		else
			vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {})
		end
	end)

	vim.api.nvim_win_set_cursor(list_win, { 1, 0 })

	vim.cmd("stopinsert")
end

-- Render preview panel
function M.render_preview(bufnr, plugin, message)
	local state = require("marketplace.state")

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	if not plugin then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
		vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
		return
	end

	local lines = {
		"Plugin: " .. plugin.name,
		"",
		"Author: " .. (plugin.author or "Unknown"),
		"Stars: " .. tostring(plugin.stars or 0),
		"",
		"Description:",
		plugin.desc,
		"",
		"Repository:",
		plugin.repo,
		"",
		"Install Path:",
		state.get_plugin_path(plugin),
	}

	-- Optional status message (install/update feedback)
	if message then
		table.insert(lines, "")
		table.insert(lines, "Status:")
		table.insert(lines, message)
	end

	-- Add placeholder for lockfile status
	table.insert(lines, "")
	table.insert(lines, "Lockfile Status:")

	local lock_status_line = #lines + 1
	table.insert(lines, "Checking...")

	-- Add health check
	table.insert(lines, "")
	table.insert(lines, "Health:")

	local health_status_line = #lines + 1
	table.insert(lines, "Checking...")

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	--Async health check
	state.health_check(plugin, function(status)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

				vim.api.nvim_buf_set_lines(bufnr, health_status_line - 1, health_status_line, false, { status })

				vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
			end
		end)
	end)

	-- Async drift check
	state.check_drift(plugin, function(status)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

				vim.api.nvim_buf_set_lines(bufnr, lock_status_line - 1, lock_status_line, false, { status })

				vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
			end
		end)
	end)
end

return M
