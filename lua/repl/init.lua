-- rrepl.lua: a minimal "send code to a REPL in a split" plugin for Neovim.
--
--   :RRepl          start the REPL in a vertical split, or hide/show it
--   :RSend          send the whole file
--   :'<,'>RSend     send the visual selection (just press : in visual mode)
--   :.RSend         send the current line
--   :1,.RSend       send from the top of the file to the cursor

local M = {}

M.cmd = "R"   -- program to run (could be "radian", "python3", "ipython", ...)
local buf     -- buffer number of the REPL terminal
local job     -- job id of the REPL process (we send text to it)

-- Is the REPL process still running? (jobwait returns -1 while it is)
local function alive()
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

-- Window currently showing the REPL, or nil if it is hidden
local function repl_win()
  local win = buf and vim.fn.bufwinid(buf) or -1
  if win ~= -1 then return win end
end

-- COMMAND 1: start the REPL, or toggle its visibility
function M.toggle()
  local win = repl_win()
  if win then                        -- visible -> hide (R keeps running)
    vim.api.nvim_win_hide(win)
    return
  end
  vim.cmd("vsplit")
  if alive() then
    vim.api.nvim_win_set_buf(0, buf) -- hidden -> show it again
  else
    vim.cmd.terminal(M.cmd)          -- not running -> start it
    buf = vim.api.nvim_get_current_buf()
    job = vim.b.terminal_job_id
  end
  vim.cmd("wincmd p")                -- jump back to the code window
end

-- COMMANDS 2/3: send lines first..last of the current buffer
function M.send(first, last)
  if not alive() then
    vim.notify("REPL not running, start it with :RRepl", vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  vim.api.nvim_chan_send(job, table.concat(lines, "\n") .. "\n")

  -- Put the REPL cursor on its last line, so the window follows the output
  local win = repl_win()
  if win then
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
end

function M.setup(opts)
  M.cmd = (opts and opts.cmd) or M.cmd

  vim.api.nvim_create_user_command("RRepl", M.toggle, {})
  -- range = "%": with no range given, the default is the whole file
  vim.api.nvim_create_user_command("RSend", function(o)
    M.send(o.line1, o.line2)
  end, { range = "%" })

  local map = vim.keymap.set
  map("n", "<leader>rr", M.toggle,            { desc = "REPL: start / toggle" })
  map("n", "<leader>rs", ":RSend<CR>",        { desc = "REPL: send file" })
  map("x", "<leader>rs", ":RSend<CR>",        { desc = "REPL: send selection" })
  map("n", "<leader>rl", ":.RSend<CR>",       { desc = "REPL: send line" })
  map("n", "<leader>rv", ":'<,'>RSend<CR>",   { desc = "REPL: resend last selection" })
  map("n", "<leader>rc", ":1,.RSend<CR>",     { desc = "REPL: send top to cursor" })
end

return M
