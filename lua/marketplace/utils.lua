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

function M.run_async_stream(cmd, on_progress, on_done)
	vim.system(cmd, {
		text = true,
		stderr = function(err, data)
			if data then
				vim.schedule(function()
					on_progress(data)
				end)
			end
		end
	}, function(obj)
		local success = obj.code == 0
		vim.schedule(function()
			on_done(success, obj.stdout or obj.stderr)
		end)
	end)
end

return M
