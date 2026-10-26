-- :Workspace -- edit the .workspace file in force (lua/workspace.lua), or start
-- one in the cwd prefilled from templates/workspace.
vim.api.nvim_create_user_command("Workspace", function()
    local ws = require("workspace").find()
    vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(ws and ws.root or vim.fn.getcwd(), ".workspace")))
    if not ws then
        local template = vim.fn.stdpath("config") .. "/templates/workspace"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.readfile(template))
    end
end, { desc = "edit the .workspace file" })
