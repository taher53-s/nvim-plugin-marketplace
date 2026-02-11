-- Responsible for rendering the marketplace list buffer
-- Handles rendering, navigation, highlighting, and search

local M = {}

local state = require("marketplace.state")

-- Namespace for highlights
local ns = vim.api.nvim_create_namespace("marketplace")

-- Layout:
-- Line 1: Title
-- Line 2: Empty spacer
-- Line 3+: Plugin list starts
local LIST_START_LINE = 3

---------------------------------------------------------------------
-- Render marketplace list
---------------------------------------------------------------------
function M.render(bufnr, all_items, on_select)
	local items = state.filter(all_items)

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	local lines = {}

	-- Title
	table.insert(lines, "🛒 Plugin Marketplace")
	table.insert(lines, "")

	-- Plugin list / empty state
	if #items == 0 then
		table.insert(lines, "No plugins found")
	else
		for i, item in ipairs(items) do
			table.insert(lines, i .. ". " .. item.name)
		end
	end

	-- Footer
	table.insert(lines, "")
	if state.query ~= "" then
		table.insert(lines, "Search: " .. state.query .. "   (Esc to clear)")
	else
		table.insert(lines, "j/k: move   Enter: preview   /: search   q: quit")
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-----------------------------------------------------------------
	-- Apply static highlights
	-----------------------------------------------------------------
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceTitle", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceFooter", #lines - 1, 0, -1)

	-----------------------------------------------------------------
	-- Handle empty results safely
	-----------------------------------------------------------------
	if #items == 0 then
		state.current_index = 0
		on_select(nil)
		return
	end

	-- Clamp selection
	if state.current_index < 1 then
		state.current_index = 1
	elseif state.current_index > #items then
		state.current_index = #items
	end

	M.update_selection(bufnr, items, on_select)

	-----------------------------------------------------------------
	-- Keymaps
	-----------------------------------------------------------------
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		M.update_selection(bufnr, items, on_select)
	end, { buffer = bufnr })

	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		M.update_selection(bufnr, items, on_select)
	end, { buffer = bufnr })

	vim.keymap.set("n", "<CR>", function()
		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	vim.keymap.set("n", "/", function()
		vim.ui.input({ prompt = "Search: " }, function(input)
			state.query = input or ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	vim.keymap.set("n", "<Esc>", function()
		if state.query ~= "" then
			state.query = ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end
	end, { buffer = bufnr })

	-- disable insert mode
	vim.keymap.set("n", "i", "<Nop>", { buffer = bufnr })
	vim.keymap.set("n", "a", "<Nop>", { buffer = bufnr })
	vim.keymap.set("n", "o", "<Nop>", { buffer = bufnr })
end

---------------------------------------------------------------------
-- Update cursor, highlight, and preview
---------------------------------------------------------------------
function M.update_selection(bufnr, items, on_select)
	if state.current_index == 0 then
		return
	end

	vim.api.nvim_win_set_cursor(0, {
		LIST_START_LINE + state.current_index - 1,
		0,
	})

	M.highlight(bufnr)

	local plugin = items[state.current_index]
	if plugin then
		on_select(plugin)
	end
end

---------------------------------------------------------------------
-- Highlight selected plugin
---------------------------------------------------------------------
function M.highlight(bufnr)
	-- Clear only selection highlight
	vim.api.nvim_buf_clear_namespace(bufnr, ns, LIST_START_LINE - 1, -1)

	if state.current_index == 0 then
		return
	end

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", LIST_START_LINE + state.current_index - 2, 0, -1)
end

return M
