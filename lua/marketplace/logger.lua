local M = {}

M.level = "info" -- "info" | "warn" | "error" | "debug"

local levels = {
	debug = 1,
	info = 2,
	warn = 3,
	error = 4,
}

local function should_log(msg_level)
	return levels[msg_level] >= levels[M.level]
end

local function log(msg_level, message)
	if not should_log(msg_level) then
		return
	end

	vim.schedule(function()
		vim.notify(
			"[Marketplace] " .. message,
			({
				debug = vim.log.levels.DEBUG,
				info = vim.log.levels.INFO,
				warn = vim.log.levels.WARN,
				error = vim.log.levels.ERROR,
			})[msg_level]
		)
	end)
end

function M.debug(msg)
	log("debug", msg)
end
function M.info(msg)
	log("info", msg)
end
function M.warn(msg)
	log("warn", msg)
end
function M.error(msg)
	log("error", msg)
end

return M
