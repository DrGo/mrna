vim.api.nvim_create_user_command("GoRun", function (opts)
	require("mrna").go_run(opts.fargs[1])
end , {nargs="?", complete="file",})
vim.api.nvim_create_user_command("Nnn", function(opts)
	local dir = ""
	if opts and #opts.fargs == 1 then
		dir = opts.fargs[1]
	end
	require("mrna/files").Nnn(dir)
end, { nargs = "?", complete = "dir", })
