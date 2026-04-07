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
		local filtered = state.filter(all_items)
		local plugin = filtered[state.current_index]
		if not plugin then
			return
		end

		state.install(plugin, function()
			M.render(bufnr, all_items, on_select)
		end)

		M.render(bufnr, all_items, on_select)
	end, { buffer = bufnr })

	-- Uninstall
	vim.keymap.set("n", "u", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]
		if not plugin then
			return
		end

		on_select(plugin, "Uninstalling...")
		state.uninstall(plugin)
		on_select(plugin, "Uninstalled successfully")
		M.render(bufnr, all_items, on_select)
	end, { buffer = bufnr })

	-- Update
	vim.keymap.set("n", "U", function()
		local items = state.filter(all_items)
		local plugin = items[state.current_index]
		if not plugin then
			return
		end

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
	end, { buffer = bufnr })

	-- Update all
	vim.keymap.set("n", "A", function()
		state.update_all(function()
			M.render(bufnr, all_items, on_select)
		end)
	end, { buffer = bufnr })

	-- Restore
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

	-- Manual refresh (clears drift cache and re-renders)
	vim.keymap.set("n", "r", function()
		state.clear_drift_cache()
		state.sync_installed_from_filesystem()
		M.render(bufnr, all_items, on_select)
	end, { buffer = bufnr })

	-- Category filter
	vim.keymap.set("n", "c", function()
		local categories = { "All" }
		for _, cat in ipairs(data.categories) do
			table.insert(categories, cat)
		end

		vim.ui.select(categories, { prompt = "Filter by category:" }, function(choice)
			if choice == "All" then
				state.category_filter = ""
			else
				state.category_filter = choice
			end
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

	-- Clear ALL highlights before rebuilding
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local lines = {}

	local title = "🛒 Plugin Marketplace"
	if state.category_filter ~= "" then
		title = title .. "  |  📂 " .. state.category_filter
	end
	table.insert(lines, title)
	table.insert(lines, "")

	-- Smart update badge: count outdated and untracked plugins
	local outdated_count = 0
	local untracked_count = 0
	for _, item in ipairs(items) do
		if state.is_installed(item) then
			local s = state.drift_cache[item.name]
			if s == "Outdated" then
				outdated_count = outdated_count + 1
			elseif s == "Untracked" then
				untracked_count = untracked_count + 1
			end
		end
	end
	if outdated_count > 0 then
		table.insert(lines, "🔄 " .. outdated_count .. " update(s) available   ⬆ use U to update")
	end
	if untracked_count > 0 then
		table.insert(lines, "⚠ " .. untracked_count .. " untracked plugin(s)")
	end
	if outdated_count > 0 or untracked_count > 0 then
		table.insert(lines, "")
	end

	if #items == 0 then
		table.insert(lines, "No plugins found")
	else
		for i, item in ipairs(items) do
			local label = i .. ". " .. item.name

			if state.installing[item.name] then
				label = label .. "   ⏳ Installing"
			elseif state.is_installed(item) then
				local drift_status = state.drift_cache[item.name]
				if drift_status == "Outdated" then
					label = label .. "   ✅ Installed ⬆ Outdated"
				elseif drift_status == "Untracked" then
					label = label .. "   ✅ Installed ⚠ Untracked"
				else
					label = label .. "   ✅ Installed"
				end

				-- Background drift check (async, updates cache)
				state.check_drift_cached(item, function(status)
					if status ~= drift_status and status then
						vim.schedule(function()
							if vim.api.nvim_buf_is_valid(bufnr) then
								M.render(bufnr, all_items, on_select)
							end
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
			"j/k: move   i: install   u: uninstall   U: update   A: update all   R: restore   r: refresh   c: category   /: search   q: quit"
		)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Highlight title and footer
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceTitle", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceFooter", #lines - 1, 0, -1)

	-- Empty state handling
	if #items == 0 then
		state.current_index = 0
		on_select(nil)
		return
	end

	-- Clamp selection safely
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
	if state.current_index == 0 then
		return
	end

	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", LIST_START_LINE + state.current_index - 2, 0, -1)
end

return M
