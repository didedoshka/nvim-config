return
{
    "neovim/nvim-lspconfig",
    config = function()
        -- keymaps
        vim.keymap.set("n", "<leader>li", function() vim.cmd("LspInfo") end)
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
        vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition)
        vim.keymap.set("n", "K", vim.lsp.buf.hover)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help)
        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder)
        vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
        vim.keymap.set("n", "gr", vim.lsp.buf.references)
        vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format { async = true }
        end)
        -- servers

        -- lua_language_server
        require("lspconfig")["lua_ls"].setup({
            capabilities = capabilities,

            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = { 'vim' },
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        checkThirdParty = false,
                        library = vim.api.nvim_get_runtime_file("", true),
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = {
                        enable = false,
                    },

                    hint = { enable = true }
                },
            }
        })

        -- pyright
        require("lspconfig")["pyright"].setup({
            capabilities = capabilities
        })

        -- clangd
        require("lspconfig")["clangd"].setup({
            capabilities = capabilities
        })


        -- cmake
        require("lspconfig")["cmake"].setup({
            capabilities = capabilities
        })

        require 'lspconfig'.typst_lsp.setup {
            settings = {
                exportPdf = "onType" -- Choose onType, onSave or never.
            },
            root_dir = function(fname)
                return require('lspconfig').util.root_pattern 'template.typ' (fname)
            end,
            capabilities = capabilities
        }

        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(ev)
                vim.lsp.inlay_hint.enable(0, true)
            end,
        })
    end,

}
