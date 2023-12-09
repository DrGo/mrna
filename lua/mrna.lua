local module = require("mrna.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.hello = function()
  module.hello()
end

M.go_run= function (fname)
	module.go_run(fname)
end
return M
