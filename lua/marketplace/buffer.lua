-- Responsible for rendering the list buffer
-- Handles rendering, navigation, highlighting, and search
-- This module owns the LIST UI logic only (no window creation)

local M = {}

-- Number of lines before the plugin list starts
-- 1: Title
-- 2: Empty spacer
local LIST_START_LINE = 3

local state = require("marketplace.state")

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace("marketplace")

---------------------------------------------------------------------
-- Render marketplace list
-- @param bufnr number: buffer number
-- @param all_items table: full plugin list
-- @param on_select function: callback when an item is selected
---------------------------------------------------------------------
function M.render(bufnr, all_items, on_select)
	-- Apply search filter
	local items = state.filter(all_items)

	-- Allow buffer edits
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	local lines = {}

	-----------------------------------------------------------------
	-- Header
	-----------------------------------------------------------------
	lines[#lines + 1] = "🛒 Plugin Marketplace"
	lines[#lines + 1] = ""

	-----------------------------------------------------------------
	-- Plugin list
	-----------------------------------------------------------------
	if #items == 0 then
		lines[#lines + 1] = "No plugins found"
	else
		for i, item in ipairs(items) do
			lines[#lines + 1] = i .. ". " .. item.name
		end
	end

	-----------------------------------------------------------------
	-- Footer
	-----------------------------------------------------------------
	lines[#lines + 1] = ""

	if state.query ~= "" then
		lines[#lines + 1] = "Search: " .. state.query .. "   (Esc to clear)"
	else
		lines[#lines + 1] = "j/k: move   Enter: preview   /: search   q: quit"
	end

	-- Write buffer
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-----------------------------------------------------------------
	-- Clamp selection index
	-----------------------------------------------------------------
	if state.current_index < 1 then
		state.current_index = 1
	elseif state.current_index > #items then
		state.current_index = #items
	end

	-----------------------------------------------------------------
	-- Move cursor to selected item
	-----------------------------------------------------------------
	if #items > 0 then
		vim.api.nvim_win_set_cursor(0, {
			LIST_START_LINE + state.current_index - 1,
			0,
		})
	end

	-- Highlight selection
	M.highlight(bufnr)

	-----------------------------------------------------------------
	-- Keymaps (buffer-local)
	-----------------------------------------------------------------

	-- j → move down
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		M.render(bufnr, all_items, on_select)

		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	-- k → move up
	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		M.render(bufnr, all_items, on_select)

		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	-- Enter → select plugin
	vim.keymap.set("n", "<CR>", function()
		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	-- / → search
	vim.keymap.set("n", "/", function()
		vim.ui.input({ prompt = "Search: " }, function(input)
			state.query = input or ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	-- Esc → clear search
	vim.keymap.set("n", "<Esc>", function()
		if state.query ~= "" then
			state.query = ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end
	end, { buffer = bufnr })
end

---------------------------------------------------------------------
-- Highlight currently selected plugin
---------------------------------------------------------------------
function M.highlight(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	if state.current_index > 0 then
		vim.api.nvim_buf_add_highlight(
			bufnr,
			ns,
			"MarketplaceSelected",
			LIST_START_LINE + state.current_index - 2,
			0,
			-1
		)
	end
end

return M
