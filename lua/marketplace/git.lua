local M = {}
local utils = require("marketplace.utils")

-------------------------------------------------
-- Clone repository
-------------------------------------------------
function M.clone(repo, path, callback)
	local cmd = {
		"git",
		"clone",
		"--depth",
		"1",
		repo,
		path,
	}

	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			callback(success, output)
		end)
	end)
end

-------------------------------------------------
-- Pull repository
-------------------------------------------------
function M.pull(path, callback)
	local cmd = {
		"git",
		"-C",
		path,
		"pull",
	}

	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			callback(success, output)
		end)
	end)
end

-------------------------------------------------
-- Get current commit hash
-------------------------------------------------
function M.get_commit(path, callback)
	local cmd = {
		"git",
		"-C",
		path,
		"rev-parse",
		"HEAD",
	}

	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			if success then
				callback(true, vim.trim(output))
			else
				callback(false, nil)
			end
		end)
	end)
end

-------------------------------------------------
-- Get current branch
-------------------------------------------------
function M.get_branch(path, callback)
	local cmd = {
		"git",
		"-C",
		path,
		"rev-parse",
		"--abbrev-ref",
		"HEAD",
	}

	utils.run_async(cmd, function(success, output)
		vim.schedule(function()
			if success then
				callback(true, vim.trim(output))
			else
				callback(false, nil)
			end
		end)
	end)
end

return M
