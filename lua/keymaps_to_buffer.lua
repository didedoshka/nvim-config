vim.keymap.set("n", "<leader>y", function ()
    local buf = vim.api.nvim_create_buf(false, false)
    local result_leader = vim.api.nvim_exec2("nmap <leader>", {output = true})
    local result_backspace = vim.api.nvim_exec2("nmap <bs>", {output = true})
    -- print(dump(result))
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, vim.split(result_leader["output"], '\n'))
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, vim.split(result_backspace["output"], '\n'))

    vim.api.nvim_set_current_buf(buf)
    vim.cmd("%s/\\*.*\\n/")
    vim.cmd("%s/^\\n/")
    vim.cmd("sort")
end, {desc = "output keymaps to a buffer"})

