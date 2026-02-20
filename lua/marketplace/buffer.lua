-- Responsible for rendering the marketplace list buffer
-- Handles rendering, navigation, highlighting, and search

local M = {}

local state = require("marketplace.state")

local ns = vim.api.nvim_create_namespace("marketplace")

-- Layout:
-- Line 1: Title
-- Line 2: Empty spacer
-- Line 3+: Plugin list
local LIST_START_LINE = 3

---------------------------------------------------------------------
-- Setup keymaps (called once per buffer)
---------------------------------------------------------------------
local function set_keymaps(bufnr, all_items, on_select)
	-- Move down
	vim.keymap.set("n", "j", function()
		local items = state.filter(all_items)
		state.move(1, #items)
		M.update_selection(bufnr, items, on_select)
	end, { buffer = bufnr })

	-- Move up
	vim.keymap.set("n", "k", function()
		local items = state.filter(all_items)
		state.move(-1, #items)
		M.update_selection(bufnr, items, on_select)
	end, { buffer = bufnr })

	-- Enter preview
	vim.keymap.set("n", "<CR>", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]
		if plugin then
			on_select(plugin)
		end
	end, { buffer = bufnr })

	-- Install
	vim.keymap.set("n", "i", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]

		if plugin then
			on_select(plugin, "Installing...")

			state.install(plugin, function(success, message)
				if success then
					on_select(plugin, message)
				else
					on_select(plugin, "Install failed")
				end
				M.render(bufnr, all_items, on_select)
			end)
		end
	end, { buffer = bufnr })

	-- Uninstall
	vim.keymap.set("n", "u", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]

		if plugin then
			on_select(plugin, "Uninstalling...")
			state.uninstall(plugin)
			on_select(plugin, "Uninstalled successfully")
			M.render(bufnr, all_items, on_select)
		end
	end, { buffer = bufnr })

	-- Update
	vim.keymap.set("n", "U", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]

		if plugin then
			if not state.is_installed(plugin) then
				on_select(plugin, "Plugin is not installed")
				return
			end

			on_select(plugin, "Updating...")

			local ok, message = state.update(plugin)

			if ok then
				on_select(plugin, message)
			else
				on_select(plugin, "Update failed")
			end
		end
	end, { buffer = bufnr })

	-------------------------------------------------------------------
	-- Update all plugins
	-------------------------------------------------------------------
	vim.keymap.set("n", "A", function()
		state.update_all(function(message)
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	-------------------------------------------------------------------
	-- Restore from lockfile
	-------------------------------------------------------------------
	vim.keymap.set("n", "R", function()
		state.restore_from_lockfile(function()
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	-- Search
	vim.keymap.set("n", "/", function()
		vim.ui.input({ prompt = "Search: " }, function(input)
			state.query = input or ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	-- Clear search
	vim.keymap.set("n", "<Esc>", function()
		if state.query ~= "" then
			state.query = ""
			state.current_index = 1
			M.render(bufnr, all_items, on_select)
		end
	end, { buffer = bufnr })
end

---------------------------------------------------------------------
-- Render list
---------------------------------------------------------------------
function M.render(bufnr, all_items, on_select)
	local items = state.filter(all_items)

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

	local lines = {}

	table.insert(lines, "🛒 Plugin Marketplace")
	table.insert(lines, "")

	if #items == 0 then
		table.insert(lines, "No plugins found")
	else
		for i, item in ipairs(items) do
			local label = i .. ". " .. item.name

			-- Installing state
			if state.installing[item.name] then
				label = label .. "   ⏳ Installing"

			-- Installed state
			elseif state.is_installed(item) then
				label = label .. "   ✅ Installed"

				-- Drift check (async, updates later)
				state.check_drift(item, function(status)
					if status == "Outdated" then
						vim.schedule(function()
							M.render(bufnr, all_items, on_select)
						end)
					end
				end)
			else
				label = label .. "   ❌ Not installed"
			end

			table.insert(lines, label)
		end
	end

	table.insert(lines, "")

	if state.query ~= "" then
		table.insert(lines, "Search: " .. state.query .. "   (Esc to clear)")
	else
		table.insert(
			lines,
			"j/k: move   i: install   u: uninstall   U: update   A: update all   R: restore   /: search   q: quit"
		)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	-------------------------------------------------
	-- Highlight installed plugins
	-------------------------------------------------
	for i, item in ipairs(items) do
		if state.is_installed(item) then
			vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceInstalled", LIST_START_LINE + i - 1, 0, -1)
		end
	end

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceTitle", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceFooter", #lines - 1, 0, -1)

	if #items == 0 then
		state.current_index = 0
		on_select(nil)
		return
	end

	if state.current_index < 1 then
		state.current_index = 1
	elseif state.current_index > #items then
		state.current_index = #items
	end

	M.update_selection(bufnr, items, on_select)

	if not vim.b[bufnr].marketplace_mapped then
		set_keymaps(bufnr, all_items, on_select)
		vim.b[bufnr].marketplace_mapped = true
	end
end

---------------------------------------------------------------------
-- Update selection
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
-- Highlight selection
---------------------------------------------------------------------
function M.highlight(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, LIST_START_LINE - 1, -1)

	if state.current_index == 0 then
		return
	end

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", LIST_START_LINE + state.current_index - 2, 0, -1)
end

return M
