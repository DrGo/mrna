local M = {}
-- local api= vim.api
local fn = vim.fn

function M.grep1(cmd)
	local res = { "" }
	local function handle_event(jid, data, event)
		vim.notify("insde grep()")
		if event == "stdout" then
			if data then
				vim.list_extend(res, data)
			end
		elseif event == "stderr" then
			vim.notify("error " .. data[1])
		elseif event == "exit" then
			fn.setqflist({}, "r", {
				title = cmd,
				lines = res,
			})
			vim.cmd("doauthocmd QuickFixCmdPost")
		end
	end

	local _ = fn.jobstart(cmd, {
		on_stderr = handle_event,
		on_stdout = handle_event,
		on_exit = handle_event,
		stdout_buffered = true,
		stderr_buffered = true,
	})
end

	local Job = require 'plenary.job'
function M.grep(opt)
	Job:new({
		command = 'rg',
		args ={opt},
		-- args = { '--files' },
		-- cwd = '/home',
		-- env = { ['a'] = 'b' },
		on_stdout=function(error, data)
			print(error)
			print(data)
		end, 
		on_stderr=function(error, data)
			print(error)
			print(data)
		end, 
		on_exit = function(j, return_val)
			print(return_val)
			print(j:result())
		end,
	}):start()
end

return M
