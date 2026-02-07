-- Responsible for rendering the list buffer
-- Handles navigation, highlighting, and search

local M = {}

local state = require("marketplace.state")
local ns = vim.api.nvim_create_namespace("marketplace")

-- render list
function M.render(bufnr, all_items, on_select)
	-- apply filter
	local items = state.filter(all_items)

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	local lines = {}

	-- plugin list
	for i, item in ipairs(items) do
		table.insert(lines, i .. ". " .. item.name)
	end

	-- spacer
	table.insert(lines, "")

	-- footer
	if state.query ~= "" then
		table.insert(lines, "Search: " .. state.query .. "   (Esc to clear)")
	else
		table.insert(lines, "j/k: move   Enter: preview   /: search   q: quit")
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- reset selection if needed
	if state.current_index > #items then
		state.current_index = #items
	end
	if state.current_index < 1 then
		state.current_index = 1
	end

	M.highlight(bufnr)

	-- navigation
	vim.keymap.set("n", "j", function()
		state.move(1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)

		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	vim.keymap.set("n", "k", function()
		state.move(-1, #items)
		vim.api.nvim_win_set_cursor(0, { state.current_index, 0 })
		M.highlight(bufnr)

		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	-- enter → select
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

-- highlight selected item
function M.highlight(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", state.current_index - 1, 0, -1)
end

return M
