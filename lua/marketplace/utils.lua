local M = {}

-------------------------------------------------
-- Run async system command
-- callback(success, output)
-------------------------------------------------
function M.run_async(cmd, callback)
	vim.system(cmd, { text = true }, function(obj)
		local success = obj.code == 0
		callback(success, obj.stdout or obj.stderr)
	end)
end

return M
