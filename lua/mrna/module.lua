local Job = require("plenary.job")
local Path = require("plenary.path")
local window = require("plenary.window.float")
---@class CustomModule
local M = {}

---@return string
M.hello = function()
  return "hello world!"
end

M.create_window = function(range_x, range_y)
  local win = window.percentage_range_window(tonumber(range_x), tonumber(range_y))
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "q",
                              ":lua require('mrna').close_win()<cr>",
                              {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(win.bufnr, "n", "<Esc>",
                              ":lua require('mrna').close_win()<cr>",
                              {noremap = true, silent = true})

  return win
end
M.close_win = function()
  vim.api.nvim_win_close(0, true)
end

-- :GoRun
M.go_run = function(file)
  local fname= file 
  if fname== "" then 
    fname= vim.fn.expand("%")
  end 
  local win = M.create_window("0.4", "0.4")
  local job_id = vim.api.nvim_open_term(win.bufnr, {})
  Job:new{
    "go",
    "run",
    fname,
    on_stdout = vim.schedule_wrap(function(_, data)
      vim.api.nvim_chan_send(job_id, data .. "\r\n")
    end),
    on_stderr = vim.schedule_wrap(function(_, data)
      vim.api.nvim_chan_send(job_id, data .. "\r\n")
	  M.close_win()
	  vim.notify("failed\r\n".. data)
    end),
	on_failure = function ()
		print("failed")
	end
  }:start()
end


return M
