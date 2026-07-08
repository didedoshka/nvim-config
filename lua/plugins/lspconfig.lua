return
{
    "neovim/nvim-lspconfig",

    dependencies = {
        "ray-x/lsp_signature.nvim",
        "nvimtools/none-ls.nvim",
    },

    config = function()
        vim.keymap.set("n", "<leader>lh", function() vim.cmd("checkhealth vim.lsp") end, { desc = "(l)sp (h)ealth" })
        vim.keymap.set("n", "<leader>le", function() vim.cmd("lsp enable") end, { desc = "(l)sp (e)nable" })
        vim.keymap.set("n", "<leader>ld", function() vim.cmd("lsp disable") end, { desc = "(l)sp (d)isable" })

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
            root_markers = { "compile_commands.json" },
            on_attach = function(client, bufnr)
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
                vim.keymap.set('n', '<leader>k', function()
                        client:request('textDocument/switchSourceHeader', {
                                uri = vim.uri_from_bufnr(bufnr),
                            },
                            function(err, result)
                                if err or not result then
                                    vim.notify('Could not find counterpart file', vim.log.levels.WARN)
                                    return
                                end
                                vim.cmd('edit ' .. vim.uri_to_fname(result))
                            end, 0
                        )
                    end,
                    { buffer = bufnr, desc = "switch cpp/hpp" })
            end,
            -- cmd = { "docker", "exec", "-i", "name", "clangd" },
            -- cmd = { "/Users/didedoshka/.local/bin/clangd", }, -- clangd 21
            cmd = {
                "ya", "tool", "clangd",
                -- "clangd",
                "--background-index",
                "-j=32",
                "--header-insertion=never",
                "--pch-storage=memory"
            },
        })
        vim.lsp.enable("clangd")

        -- cmake
        vim.lsp.enable("cmake")

        vim.lsp.config("tinymist", {
            settings = {
                formatterMode = "typstyle",
                exportPdf = "never",
                semanticTokens = "disable"
            },
            root_markers = { "template.typ" },
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

        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.cmake_format,
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.formatting.clang_format.with({
                    command = { "ads-clang-format" },
                }),
            }
        })

        -- vim.lsp.enable('jsonls')

        -- jump to the header of the enclosing symbol of one of `kinds` (via LSP documentSymbol)
        local SK = vim.lsp.protocol.SymbolKind
        local function goto_enclosing(kinds)
            local bufnr = 0
            local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
            local res = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
            if not res then return end

            local cur = vim.api.nvim_win_get_cursor(0)
            local row, col = cur[1] - 1, cur[2]
            local function contains(r)
                if row < r.start.line or row > r["end"].line then return false end
                if row == r.start.line and col < r.start.character then return false end
                if row == r["end"].line and col > r["end"].character then return false end
                return true
            end

            local best
            local function walk(syms)
                for _, s in ipairs(syms or {}) do
                    local r = s.range or (s.location and s.location.range)
                    if r and contains(r) then
                        if kinds[s.kind] then best = s end
                        walk(s.children)
                    end
                end
            end
            for _, r in pairs(res) do walk(r.result) end

            if not best then
                vim.notify("no enclosing symbol", vim.log.levels.INFO)
                return
            end
            local p = (best.selectionRange or best.range).start
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { p.line + 1, p.character })
        end

        -- walk up the enclosing scope chain: innermost first, then one level up per press
        local scope_kinds = {
            [SK.Function] = true, [SK.Method] = true, [SK.Constructor] = true,
            [SK.Class] = true, [SK.Struct] = true, [SK.Interface] = true,
            [SK.Enum] = true, [SK.Namespace] = true, [SK.Module] = true,
        }
        local function goto_scope_up()
            local params = { textDocument = vim.lsp.util.make_text_document_params(0) }
            local res = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
            if not res then return end

            local cur = vim.api.nvim_win_get_cursor(0)
            local row, col = cur[1] - 1, cur[2]
            local function contains(r)
                if row < r.start.line or row > r["end"].line then return false end
                if row == r.start.line and col < r.start.character then return false end
                if row == r["end"].line and col > r["end"].character then return false end
                return true
            end

            local chain = {} -- outermost -> innermost
            local function walk(syms)
                for _, s in ipairs(syms or {}) do
                    local r = s.range or (s.location and s.location.range)
                    if r and contains(r) then
                        if scope_kinds[s.kind] then chain[#chain + 1] = s end
                        walk(s.children)
                    end
                end
            end
            for _, r in pairs(res) do walk(r.result) end
            if #chain == 0 then
                vim.notify("no enclosing scope", vim.log.levels.INFO)
                return
            end

            local target = chain[#chain] -- default: innermost
            for i, s in ipairs(chain) do -- already on a header? step to its parent
                local h = (s.selectionRange or s.range).start
                if h.line == row and h.character == col then
                    if i == 1 then
                        vim.notify("at outermost scope", vim.log.levels.INFO)
                        return
                    end
                    target = chain[i - 1]
                    break
                end
            end
            local p = (target.selectionRange or target.range).start
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { p.line + 1, p.character })
        end

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
                    vim.keymap.set("n", "<leader>v", function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
                    end, { buffer = bufnr, desc = "toggle inlay hints" })
                end

                -- jump to enclosing function / class definition
                if client.server_capabilities.documentSymbolProvider then
                    vim.keymap.set("n", "[f", function()
                        goto_enclosing({ [SK.Function] = true, [SK.Method] = true, [SK.Constructor] = true })
                    end, { buffer = bufnr, desc = "enclosing (f)unction" })
                    vim.keymap.set("n", "[c", function()
                        goto_enclosing({ [SK.Class] = true, [SK.Struct] = true, [SK.Interface] = true, [SK.Enum] = true })
                    end, { buffer = bufnr, desc = "enclosing (c)lass" })
                    vim.keymap.set("n", "go", goto_scope_up, { buffer = bufnr, desc = "(g)o to enclosing scope/(o)ut" })
                end

                -- basic keymaps
                local opts = { buffer = args.buf }
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { buffer = args.buf, desc = "(d)iagnostic" })
                vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
                vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
                -- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
                vim.keymap.set("n", "<leader>j", vim.diagnostic.setqflist,
                    { buffer = args.buf, desc = "diagnostics to quickfixlist" })
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
                vim.keymap.set('n', 'gr', require('fzf-lua').lsp_references, opts)
                vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
                    vim.lsp.buf.format { async = true }
                end, { buffer = args.buf, desc = "(f)ormat" })
            end,
        })
    end,

}
