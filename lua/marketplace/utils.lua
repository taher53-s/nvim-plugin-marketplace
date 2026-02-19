local M = {}

-------------------------------------------------
-- Run a shell command safely
-- Returns:
--   success (boolean)
--   output (string)
-------------------------------------------------
function M.run(cmd)
	local result = vim.fn.system(cmd)
	local success = vim.v.shell_error == 0
	return success, result
end

return M
