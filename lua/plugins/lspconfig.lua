return
{
    "neovim/nvim-lspconfig",
    config = function()
        -- keymap for LspInfo window
        vim.keymap.set("n", "<leader>li", function() vim.cmd("LspInfo") end)

        -- servers
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- lua_language_server
        require("lspconfig")["lua_ls"].setup({
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
            callback = function(args)
                -- get buffer number and client info
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)

                -- turn inlay_hint on
                if client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(bufnr, true)
                end

                -- basic keymaps
                local opts = { buffer = args.buf }
                vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
                vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
                vim.keymap.set('n', '<space>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, opts)
                vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
                vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
                vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', '<space>f', function()
                    vim.lsp.buf.format { async = true }
                end, opts)
            end,
        })
    end,

}
