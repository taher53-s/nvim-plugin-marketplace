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

-------------------------------------------------
-- Parallel clone: run multiple clones concurrently (max concurrency)
-------------------------------------------------
local clone_semaphore = {}
clone_semaphore.running = 0
clone_semaphore.concurrency = 3
clone_semaphore.queue = {}

function M.clone_parallel(entries, on_all_done)
	-- entries: { { repo, path }, ... }
	-- on_all_done: called when all complete

	local total = #entries
	if total == 0 then
		if on_all_done then on_all_done() end
		return
	end

	local completed = 0
	local results = {}

	local function check_done()
		completed = completed + 1
		if completed == total and on_all_done then
			on_all_done(results)
		end
	end

	local function do_next()
		while clone_semaphore.running < clone_semaphore.concurrency and #clone_semaphore.queue > 0 do
			local entry = table.remove(clone_semaphore.queue, 1)
			clone_semaphore.running = clone_semaphore.running + 1

			M.clone(entry.repo, entry.path, function(success)
				clone_semaphore.running = clone_semaphore.running - 1
				results[#results + 1] = { repo = entry.repo, path = entry.path, success = success }
				check_done()
				do_next()  -- process next in queue
			end)
		end
	end

	for _, entry in ipairs(entries) do
		table.insert(clone_semaphore.queue, entry)
	end

	-- Start max concurrency
	for i = 1, math.min(clone_semaphore.concurrency, total) do
		local entry = table.remove(clone_semaphore.queue, 1)
		clone_semaphore.running = clone_semaphore.running + 1

		M.clone(entry.repo, entry.path, function(success)
			clone_semaphore.running = clone_semaphore.running - 1
			results[#results + 1] = { repo = entry.repo, path = entry.path, success = success }
			check_done()
			do_next()
		end)
	end
end

return M
