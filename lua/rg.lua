if not vim.g.rg_command then
  vim.g.rg_command = "rg --vimgrep"
end

if not vim.g.default_dir then
  vim.g.default_dir = "./"
end

-- Change to 0 if you don't want the command to run asynchronously on Neovim
if not vim.g.rg_run_async then
  vim.g.rg_run_async = 1
end

local chunks = {""}
local error = 0
local rg_job = 0

local function Alert(msg)
  vim.api.nvim_out_write("WarningMsg: " .. msg .. "\n")
end

local function ShowResults(data, title)
  vim.fn.setqflist({})
  vim.fn.setqflist({}, 'r', { context = 'file_search', title = title })
  vim.fn.setqflist(data)
  vim.cmd('copen')
  chunks = {""}
end

local function RemoveTrailingEmptyLine(lines)
  if #lines > 1 and lines[#lines] == "" then
    return vim.list_slice(lines, 1, -2)
  end
  return lines
end

local function HasQuote(item)
  return string.match(item, '^.*"$') or string.match(item, "^.*'$")
end

local function NotOption(item)
  return #item > 0 and item:sub(1, 1) ~= '-'
end

local function IsOption(item)
  return #item > 0 and item:sub(1, 1) == '-'
end

local function HasDirectory(cmd)
  local options = {
    '-t', '--type', '-T', '--type-not', '-r', '--replace',
    '--max-filesize', '-m', '--max-count', '-d', '--max-depth',
    '-M', '--max-columns', '--ignore-file', '--iglob',
    '-g', '--glob', '-f', '--file', '-E', '--encoding',
    '-A', '--after-context', '-B', '--before-context'
  }
  local cmd_parts = vim.split(cmd, ' ')
  local has_dir = 0

  if HasQuote(cmd_parts[#cmd_parts]) then
    has_dir = 0
  elseif #cmd_parts > 1 and HasQuote(cmd_parts[#cmd_parts - 1]) and NotOption(cmd_parts[#cmd_parts]) then
    has_dir = 1
  elseif #cmd_parts > 3 and vim.fn.index(options, cmd_parts[#cmd_parts - 3]) >= 0
    and NotOption(cmd_parts[#cmd_parts]) and NotOption(cmd_parts[#cmd_parts - 1])
    and NotOption(cmd_parts[#cmd_parts - 2]) and NotOption(cmd_parts[#cmd_parts - 3]) then
    has_dir = 1
  elseif #cmd_parts > 2 and IsOption(cmd_parts[#cmd_parts - 2])
    and vim.fn.index(options, cmd_parts[#cmd_parts - 2]) == -1
    and NotOption(cmd_parts[#cmd_parts]) and NotOption(cmd_parts[#cmd_parts - 1]) then
    has_dir = 1
  elseif #cmd_parts == 2 and NotOption(cmd_parts[#cmd_parts]) and NotOption(cmd_parts[#cmd_parts - 1]) then
    has_dir = 1
  end

  return has_dir
end

local function RgEvent(job_id, data, event)
  local msg = "Error: Pattern - " .. vim.fn.escape(data[1], "'") .. " - not found"

  if event == "stdout" then
    chunks[#chunks] = chunks[#chunks] .. data[1]
    table.remove(data, 1)
    vim.list_extend(chunks, data)
  elseif event == "stderr" then
    error = 1
    Alert(msg)
  elseif event == "exit" then
    if error ~= 0 then
      error = 0
      return
    end

    if rg_job == 0 then
      chunks = {""}
      return
    end

    rg_job = 0

    if chunks[1] == "" then
      Alert(msg)
      return
    end

    Alert("")
    ShowResults(RemoveTrailingEmptyLine(chunks), vim.fn.escape(data.cmd, "'"))
  end
end

local function RunCmd(cmd, pattern)
  -- Stop any long-running jobs before starting a new one
  if rg_job ~= 0 then
    vim.fn.jobstop(rg_job)
    rg_job = 0
    Alert("Search interrupted. Please try your search again.")
    return
  end

  -- Run async if Neovim
  if vim.fn.has("nvim") and vim.g.rg_run_async ~= 0 then
    Alert("Searching...")
    local opts = {
      on_stdout = vim.fn["s:RgEvent"],
      on_stderr = vim.fn["s:RgEvent"],
      on_exit = vim.fn["s:RgEvent"],
      pattern = pattern,
      cmd = cmd
    }
    rg_job = vim.fn.jobstart(cmd, opts)
    return
  end

  -- Run w/o async if Vim
  local cmd_output = vim.fn.system(cmd)
  if cmd_output == "" then
    local msg = "Error: Pattern - " .. vim.fn.escape(pattern, "'") .. " - not found"
    Alert(msg)
    return
  end

  ShowResults(cmd_output, vim.fn.escape(cmd, "'"))
end

local function RunRg(cmd)
  if #cmd > 0 then
    local cmd_options = vim.g.rg_command .. " " .. cmd .. " " .. vim.g.default_dir

    -- Check if cmd contains a directory; don't use default_dir if it does
    if HasDirectory(cmd) then
      cmd_options = vim.g.rg_command .. " " .. cmd
    end

    RunCmd(cmd_options, cmd)
    return
  end

  local pattern = vim.fn.input("Search for pattern: ")
  if pattern == "" then
    return
  end

  print("\r")
  local startdir = vim.fn.input("Start searching from directory: ", "./")
  if startdir == "" then
    return
  end

  print("\r")
  local ftype = vim.fn.input("File type (optional): ", "")
  if ftype ~= "" then
    ftype = " -t " .. ftype
  end

  print("\r")
  local cmd = vim.g.rg_command .. ftype .. " '" .. pattern .. "' " .. startdir
  RunCmd(cmd, pattern)
end

vim.cmd("command! -nargs=? -complete=file Rg lua s:RunRg(<q-args>)")
vim.api.nvim_set_keymap('n', '<leader>rg', ':Rg<CR>', { noremap = true })

