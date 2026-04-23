local M = {}
local logger = require("marketplace.logger")
local utils = require("marketplace.utils")

-- Queries GitHub for matching Neovim plugins
function M.search_github(query, callback)
	if not query or query == "" then
		if callback then callback(false, {}) end
		return
	end

	local state = require("marketplace.state")
	
	-- We construct a strict GitHub search querying "language:lua"
    local query_params = query .. "+in:name,description+language:lua"
    if state.strict_filter then
        query_params = query_params .. "+topic:neovim-plugin"
    end

	local url = "https://api.github.com/search/repositories?q=" .. query_params .. "&per_page=30"

    -- Apply active sort filtering
    if state.sort_method ~= "" then
        url = url .. "&sort=" .. state.sort_method
    end

	local cmd = { "curl", "-sL", "--connect-timeout", "5", url }

	logger.info("Searching GitHub for: " .. query)

	-- Spawn an asynchronous operating-system job so NeoVim never drops frames or freezes
	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			if success and output and output ~= "" then
				local ok, decoded = pcall(vim.fn.json_decode, output)
				if ok and type(decoded) == "table" and decoded.items then
					local results = {}
					for _, item in ipairs(decoded.items) do
						table.insert(results, {
							name = item.name,
							repo = item.html_url or item.clone_url,
							desc = item.description or "No description provided.",
							stars = item.stargazers_count or 0,
							author = item.owner and item.owner.login or "unknown",
						})
					end
					callback(true, results)
				else
					logger.warn("GitHub API: Failed to parse valid JSON payload.")
					callback(false, {})
				end
			else
				logger.warn("GitHub API: Network error occurred.")
				callback(false, {})
			end
		end)
	end)
end

return M
