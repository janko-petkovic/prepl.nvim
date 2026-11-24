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
