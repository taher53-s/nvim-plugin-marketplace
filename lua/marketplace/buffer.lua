local M = {}
local state = require("marketplace.state")
local api = require("marketplace.api")
local ns = vim.api.nvim_create_namespace("marketplace")

function M.build_display_list()
	local list = {}
	if state.search_mode then
		for _, p in ipairs(state.search_results) do
			table.insert(list, p)
		end
	else
		-- HOME DASHBOARD MODE
		table.insert(list, { is_header = true, name = "⭐ Installed Plugins" })
		local has_installed = false
		for plugin_name, _ in pairs(state.installed) do
			has_installed = true
			table.insert(list, {
				name = plugin_name,
				repo = state.lock[plugin_name] and state.lock[plugin_name].repo or "Locally installed",
				desc = "Installed mechanically on local disk.",
				author = "Local Drive",
				stars = 0
			})
		end
		
		if not has_installed then
			table.insert(list, { is_header = true, name = "   (No plugins installed natively yet)" })
		end

		table.insert(list, { is_header = true, name = "" }) -- Spacer
		table.insert(list, { is_header = true, name = "🔥 Community Recommended" })
		
		if #state.recommended == 0 and not state.is_loading then
			table.insert(list, { is_header = true, name = "   (No recommendations downloaded)" })
		end
		
		local count = 0
		for _, p in ipairs(state.recommended) do
			-- Deduplicate so installed plugins don't show twice
			if not state.installed[p.name] then
				table.insert(list, p)
				count = count + 1
				if count >= 10 then break end
			end
		end
	end
	return list
end

function M.render(bufnr, winid)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

	local lines = {}
	state.current_display = M.build_display_list()

	table.insert(lines, " 📦 Neovim Plugin Marketplace (Powered by GitHub)")
	table.insert(lines, "")

	if state.is_loading then
		table.insert(lines, "  ⏳ Searching global GitHub repository data...")
	else
		if #state.current_display == 0 then
			table.insert(lines, "  Press '/' to dynamically search plugins directly via Github.")
		else
			for i, item in ipairs(state.current_display) do
				if item.is_header then
					table.insert(lines, "  " .. item.name)
				else
					local prefix = "  "
					if i == state.current_index then prefix = "➜ " end
					
					local status = state.installed[item.name] and "✅ [Installed]" or "❌ [Available]"
					
					-- Render native streaming installation bar
					local prog = state.progress[item.name]
					if prog then
						local bars_to_show = math.floor(prog / 10)
						local bar = string.rep("█", bars_to_show) .. string.rep("░", 10 - bars_to_show)
						status = string.format("⏳  [%s] %d%%", bar, prog)
					end

					table.insert(lines, prefix .. item.name .. " " .. status)
				end
			end
		end
	end

	table.insert(lines, "")
	table.insert(lines, " -------------------------------------------------------------")
	table.insert(lines, " <CR>: Info  |  i: Install  |  u: Uninstall  |  U: Update")
	if state.search_mode then
		table.insert(lines, " /: Search | f: Sort/Filter | c/<BS>: Go Home | A: Update All | q: Quit")
	else
		table.insert(lines, " /: Search | f: Sort/Filter | A: Update All   | R: Restore    | q: Quit")
	end

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Minimal elegant highlights
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceTitle", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceFooter", #lines - 2, 0, -1)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceFooter", #lines - 1, 0, -1)

	-- Inject Right-Aligned Virtual Extmarks!
	vim.api.nvim_set_hl(0, "MarketplaceExtmarkStars", { fg = "#e3b341" })
	vim.api.nvim_set_hl(0, "MarketplaceExtmarkAuthor", { fg = "#666666", italic = true })
	
	if not state.is_loading and #state.current_display > 0 then
		for i, item in ipairs(state.current_display) do
			if not item.is_header then
				local virt_text = {}
				if item.stars and type(item.stars) == "number" and item.stars > 0 then
					table.insert(virt_text, { string.format("★ %s", item.stars), "MarketplaceExtmarkStars" })
				end
				if item.author and item.author ~= "unknown" and item.author ~= "Local Drive" then
					table.insert(virt_text, { "  | By " .. item.author, "MarketplaceExtmarkAuthor" })
				end
				if #virt_text > 0 then
					pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, 1 + i, 0, {
						virt_text = virt_text,
						virt_text_pos = "right_align",
					})
				end
			end
		end
	end

    if #state.current_display > 0 and state.current_index > 0 then
        -- Fast forward index if it somehow landed on a header
        if state.current_display[state.current_index] and state.current_display[state.current_index].is_header then
            for idx, d in ipairs(state.current_display) do
                if not d.is_header then
                    state.current_index = idx
                    break
                end
            end
        end

        -- Highlight current cursor securely with boundary checks
        if state.current_display[state.current_index] and not state.current_display[state.current_index].is_header then
            vim.api.nvim_buf_add_highlight(bufnr, ns, "MarketplaceSelected", state.current_index + 2 - 1, 0, -1)
            if vim.api.nvim_win_is_valid(winid) then
                vim.api.nvim_win_set_cursor(winid, { state.current_index + 2, 0 })
            end
        end
    end
end

function M.set_keymaps(bufnr, winid, ui_module)
	local function refresh()
		M.render(bufnr, winid)
	end
    local function get_plugin()
        local item = state.current_display[state.current_index]
        if item and not item.is_header then return item end
        return nil
    end

	vim.keymap.set("n", "j", function()
		if state.current_index < #state.current_display then
			repeat
				state.current_index = state.current_index + 1
			until state.current_index == #state.current_display or not state.current_display[state.current_index].is_header
		end
		refresh()
	end, { buffer = bufnr })

	vim.keymap.set("n", "k", function()
		if state.current_index > 1 then
			repeat
				state.current_index = state.current_index - 1
			until state.current_index == 1 or not state.current_display[state.current_index].is_header
		end
		refresh()
	end, { buffer = bufnr })

	vim.keymap.set("n", "/", function()
		vim.ui.input({ prompt = "Search Github: " }, function(input)
            if input and input ~= "" then
                state.search_mode = true
                state.last_query = input
                state.is_loading = true
                state.current_index = 1
                refresh()
                api.search_github(input, function(success, results)
                    state.is_loading = false
                    if success then state.search_results = results end
                    refresh()
                end)
            elseif input == "" then
				-- Empty query snaps straight back Home
                state.search_mode = false
                state.current_index = 1
                refresh()
            end
		end)
	end, { buffer = bufnr })

	vim.keymap.set("n", "f", function()
        local options = {
            "1. Sort by: Best Match" .. (state.sort_method == "" and " (Active)" or ""),
            "2. Sort by: Most Stars" .. (state.sort_method == "stars" and " (Active)" or ""),
            "3. Sort by: Recently Updated" .. (state.sort_method == "updated" and " (Active)" or ""),
            "4. Toggle Strict Neovim Filter" .. (state.strict_filter and " (Currently ON)" or " (Currently OFF)")
        }
        
        vim.ui.select(options, { prompt = "Filter & Sort API Results:" }, function(choice)
            if not choice then return end
            
            if choice:match("Best Match") then state.sort_method = ""
            elseif choice:match("Most Stars") then state.sort_method = "stars"
            elseif choice:match("Recently Updated") then state.sort_method = "updated"
            elseif choice:match("Strict Neovim Filter") then state.strict_filter = not state.strict_filter
            end

            if state.search_mode and state.last_query and state.last_query ~= "" then
                state.is_loading = true
                state.current_index = 1
                refresh()
                api.search_github(state.last_query, function(success, results)
                    state.is_loading = false
                    if success then state.search_results = results end
                    refresh()
                end)
            else
                vim.notify("Filter Settings Updated. Try searching to see the effect!")
            end
        end)
    end, { buffer = bufnr })

	-- Clear Search / Return Home Mappings
	local clear_search = function()
		if state.search_mode then
			state.search_mode = false
			state.current_index = 1
			vim.notify("Returned to Home Dashboard")
			refresh()
		end
	end
	vim.keymap.set("n", "c", clear_search, { buffer = bufnr })
	vim.keymap.set("n", "<BS>", clear_search, { buffer = bufnr })

    vim.keymap.set("n", "<CR>", function()
        local p = get_plugin()
        if p then ui_module.open_info_popup(p) end
    end, { buffer = bufnr })

    vim.keymap.set("n", "i", function()
        local p = get_plugin()
        if p and not state.installed[p.name] then
            state.install(p, function(percent, msg) 
                if percent then
                    state.progress[p.name] = percent
                else
                    state.progress[p.name] = nil
                    vim.notify(msg)
                end
                refresh()
            end)
        else
            vim.notify("Already installed")
        end
    end, { buffer = bufnr })

    vim.keymap.set("n", "u", function()
        local p = get_plugin()
        if p and state.installed[p.name] then
            state.uninstall(p, function(msg) vim.notify(msg) refresh() end)
        end
    end, { buffer = bufnr })

    vim.keymap.set("n", "U", function()
        local p = get_plugin()
        if p and state.installed[p.name] then
            state.update(p, function(msg) vim.notify(msg) refresh() end)
        end
    end, { buffer = bufnr })

    vim.keymap.set("n", "A", function()
        state.update_all(function(msg) vim.notify(msg) refresh() end)
    end, { buffer = bufnr })

    vim.keymap.set("n", "R", function()
        state.restore_from_lockfile(function(msg) vim.notify(msg) refresh() end)
    end, { buffer = bufnr })
end

return M
