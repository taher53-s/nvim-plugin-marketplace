local M = {}
local buffer = require("marketplace.buffer")
local state = require("marketplace.state")

function M.open(config)
	state.load_lockfile()
	state.sync_installed_from_filesystem()

	local list_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(list_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(list_buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(list_buf, "swapfile", false)
	
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.6)

	-- One monolithic list window replaces the complicated side-by-side splits
	local list_win = vim.api.nvim_open_win(list_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = config.border or "rounded",
	})

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(list_win) then vim.api.nvim_win_close(list_win, true) end
	end, { buffer = list_buf })

    -- Clean simple highlight tokens
    vim.api.nvim_set_hl(0, "MarketplaceSelected", { bg = "#2a2a2a", bold = true })
    vim.api.nvim_set_hl(0, "MarketplaceTitle", { bold = true, fg = "#58a6ff" })
    vim.api.nvim_set_hl(0, "MarketplaceFooter", { fg = "#777777" })

	local api = require("marketplace.api")

	-- Default popular fetch if the screen is totally empty
	if #state.recommended == 0 then
		state.is_loading = true
		api.search_github("topic:neovim-plugin+sort:stars", function(success, results)
			state.is_loading = false
			if success then state.recommended = results end
			
			if vim.api.nvim_win_is_valid(list_win) then
				buffer.render(list_buf, list_win)
			end
		end)
	end

	buffer.set_keymaps(list_buf, list_win, M)
	buffer.render(list_buf, list_win)

	vim.cmd("stopinsert")
end

-- New dynamic modal popup overlay
function M.open_info_popup(plugin)
    local info_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(info_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(info_buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(info_buf, "swapfile", false)

    local lines = {
        " ℹ️  Plugin Information via GitHub",
        "",
        "  Name:   " .. plugin.name,
        "  Repo:   " .. plugin.repo,
        "  Author: " .. plugin.author,
        "  Stars:  ★ " .. (plugin.stars or 0),
        "",
        "  Description: ",
        "  " .. plugin.desc,
        "",
        " ----------------------------------",
        "  Press 'q', 'Esc', or '<CR>' to close this popup"
    }

	vim.api.nvim_buf_set_lines(info_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(info_buf, "modifiable", false)

	local width = 60
	local height = 15

	-- Pops over the existing elements gracefully and offset
	local winid = vim.api.nvim_open_win(info_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2) + 2,
		col = math.floor((vim.o.columns - width) / 2) + 2,
		style = "minimal",
		border = "double",
	})

    local close_fn = function()
		if vim.api.nvim_win_is_valid(winid) then vim.api.nvim_win_close(winid, true) end
    end

	vim.keymap.set("n", "q", close_fn, { buffer = info_buf })
	vim.keymap.set("n", "<Esc>", close_fn, { buffer = info_buf })
    vim.keymap.set("n", "<CR>", close_fn, { buffer = info_buf })
end

return M
