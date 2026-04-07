-- Handles window creation and UI rendering

local M = {}

local buffer = require("marketplace.buffer")
local data = require("marketplace.data")
local state = require("marketplace.state")

local ns = vim.api.nvim_create_namespace("marketplace")

function M.open(config)
	state.load()
	state.load_filters()
	state.clear_drift_cache()
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

	vim.api.nvim_set_hl(0, "MarketplaceSection", {
		fg = "#58a6ff",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "MarketplaceMeta", {
		fg = "#8b949e",
	})

	vim.api.nvim_set_hl(0, "MarketplaceCategory", {
		fg = "#d2a8ff",
	})

	vim.api.nvim_set_hl(0, "MarketplaceDrift", {
		fg = "#f0c06a",
	})

	-----------------------------------------------------------------
	-- Background drift check on open (populates cache for all installed)
	-----------------------------------------------------------------
	for _, plugin in ipairs(data.plugins) do
		if state.is_installed(plugin) then
			state.check_drift_cached(plugin, function() end)
		end
	end

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

-- Render preview panel with enhanced layout
function M.render_preview(bufnr, plugin, message)
	local state = require("marketplace.state")

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	if not plugin then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
		vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
		return
	end

	-- Format star count with thousands separator
	local stars = plugin.stars or 0
	local stars_str = string.format("%,d", stars)

	local lines = {
		"◆ " .. plugin.name,
		"",
	}

	-- Metadata section
	if plugin.category then
		table.insert(lines, "  Category    " .. plugin.category)
	end
	if plugin.author then
		table.insert(lines, "  Author      " .. plugin.author)
	end
	table.insert(lines, "  Stars       " .. stars_str)
	table.insert(lines, "  Repository  " .. plugin.repo)
	table.insert(lines, "")
	table.insert(lines, "  Description")
	table.insert(lines, "  " .. plugin.desc)

	-- Dependencies
	if plugin.dependencies and #plugin.dependencies > 0 then
		table.insert(lines, "")
		table.insert(lines, "  Dependencies")
		for _, dep in ipairs(plugin.dependencies) do
			local dep_installed = state.is_installed({ name = dep }) and "✅" or "❌"
			table.insert(lines, "    " .. dep_installed .. " " .. dep)
		end
	end

	-- Installation path
	table.insert(lines, "")
	table.insert(lines, "  Install Path")
	table.insert(lines, "  " .. state.get_plugin_path(plugin))

	-- Optional status message
	if message then
		table.insert(lines, "")
		table.insert(lines, "  Status")
		table.insert(lines, "  " .. message)
	end

	-- Lockfile / drift status
	local lock_status_line = #lines + 1
	table.insert(lines, "  Lockfile")
	table.insert(lines, "  Checking...")

	-- Health status
	local health_status_line = #lines + 1
	table.insert(lines, "  Health")
	table.insert(lines, "  Checking...")

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Apply highlights
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceTitle", 0, 0, -1)

	-- Async health check
	state.health_check(plugin, function(status)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
				vim.api.nvim_buf_set_lines(bufnr, health_status_line - 1, health_status_line, false, { "  " .. status })
				vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
			end
		end)
	end)

	-- Async drift check (cached)
	state.check_drift_cached(plugin, function(status)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
				vim.api.nvim_buf_set_lines(bufnr, lock_status_line - 1, lock_status_line, false, { "  " .. status })
				vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
			end
		end)
	end)
end

return M
