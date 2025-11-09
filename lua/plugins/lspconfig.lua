return
{
    "neovim/nvim-lspconfig",

    dependencies = {
        "ray-x/lsp_signature.nvim",
    },

    config = function()
        vim.keymap.set("n", "<leader>li", function() vim.cmd("LspInfo") end, { desc = "(l)sp (i)nfo" })
        vim.keymap.set("n", "<leader>lb", function() vim.cmd("LspStart") end, { desc = "(l)sp (b)egin" })
        vim.keymap.set("n", "<leader>le", function() vim.cmd("LspStop") end, { desc = "(l)sp (e)nd" })

        local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
            opts = opts or {}
            opts.border = opts.border or "single"
            return orig_util_open_floating_preview(contents, syntax, opts, ...)
        end

        -- servers
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        -- local capabilities = require("cmp_nvim_lsp").default_capabilities({ snippetSupport = false })

        vim.lsp.config("*", {
            capabilities = capabilities,
        })

        -- lua_language_server
        vim.lsp.config("lua_ls", {
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
        vim.lsp.enable("lua_ls")

        -- pyright
        vim.lsp.config("pyright", {
            settings = {
                python = {
                    analysis = {
                        stubPath = "~/.stubs/python-type-stubs/stubs",
                        autoSearchPaths = true,
                        diagnosticMode = "openFilesOnly",
                        useLibraryCodeForTypes = true
                    }
                }
            }
        })
        vim.lsp.enable("pyright")

        -- clangd
        vim.lsp.config("clangd", {
            root_markers = { "build" },
            -- cmd = { "docker", "exec", "-i", "name", "clangd" },
        })
        vim.lsp.enable("clangd")

        -- cmake
        vim.lsp.enable("cmake")

        vim.lsp.config("tinymist", {
            settings = {
                formatterMode = "typstyle",
                exportPdf = "onType",
                semanticTokens = "disable"
            },
            root_markers = "template.typ"
        })
        vim.lsp.enable("tinymist")

        vim.lsp.config("rust_analyzer", {
            root_dir = function(bufnr, on_dir)
                local found = vim.fs.root(bufnr, "Cargo.toml")
                if found then on_dir(found) end
            end,
        })

        vim.lsp.enable("rust_analyzer")

        vim.lsp.config("ruff", {
            init_options = {
                settings = {
                    lint = {
                        enable = false
                    }
                }
            }
        })
        vim.lsp.enable("ruff")

        vim.lsp.enable("protols")

        vim.lsp.enable("gopls")

        -- require("null-ls").setup({
        --     sources = {
        --         require("null-ls").builtins.formatting.autopep8.with({
        --         extra_args = { "-a", "-a", "--max-line-length", "119" }
        --     })
        --     }
        -- })

        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                -- get buffer number and client info
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)


                -- if vim.tbl_contains({ 'null-ls' }, client.name) then -- blacklist lsp
                --     return
                -- end
                require("lsp_signature").on_attach({
                    max_height = 5,
                    hint_enable = false,
                    handler_opts = {
                        border = "single"
                    },
                    hi_parameter = "@markup.strong",

                    -- hint_prefix = "",
                    -- hint_inline = function() return "inline" end,
                }, bufnr)

                -- turn inlay_hint on
                if client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end

                -- basic keymaps
                local opts = { buffer = args.buf }
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { buffer = args.buf, desc = "(d)iagnostic" })
                vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
                vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
                -- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
                vim.keymap.set("n", "<leader>j", vim.diagnostic.setqflist, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
                -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
                -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
                -- vim.keymap.set('n', '<space>wl', function()
                --     print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                -- end, opts)
                -- vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
                vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { buffer = args.buf, desc = "(r)ename" })
                vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action,
                    { buffer = args.buf, desc = "code (a)ction" })
                vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
                vim.keymap.set('n', '<leader>f', function()
                    vim.lsp.buf.format { async = true }
                end, { buffer = args.buf, desc = "(f)ormat" })
            end,
        })
    end,

}
