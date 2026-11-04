return
{
    "nvim-treesitter/nvim-treesitter",

    -- dependencies = {
    --     {
    --         dir = yamake_treesitter_dir,
    --         -- build = ":TSInstall yamake",
    --         enabled = function()
    --             local res = vim.uv.fs_stat(yamake_treesitter_dir)
    --             vim.print(res)
    --
    --             return res ~= nil
    --         end,
    --         -- lazy = false,
    --         config = function() end,
    --     }
    -- },

    build = ":TSUpdate",
    config = function()
        vim.api.nvim_create_autocmd('FileType', {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if not lang then return end
                if vim.treesitter.language.add(lang) then
                    -- explicit: fzf-lua's preview buffer fires FileType=diff with 'filetype' unset
                    vim.treesitter.start(args.buf, lang)
                    return
                end
                local ts = require('nvim-treesitter')
                if not vim.list_contains(ts.get_available(), lang) then return end
                -- no :wait() here: it spins the event loop, and anything it runs that fires
                -- FileType (nightly's autoread :checktime) nests inside this autocmd (E218)
                ts.install(lang):await(function(err)
                    if err or not vim.api.nvim_buf_is_valid(args.buf) then return end
                    if vim.bo[args.buf].filetype ~= args.match then return end
                    vim.treesitter.start(args.buf, lang)
                end)
            end,
        })

        vim.filetype.add({
            filename = {
                ["ya.make"] = "yamake",
            },
        })

        local dir = vim.fn.expand("~/w/a/h/devtools/ide/tree-sitter-yamake")
        vim.api.nvim_create_autocmd('User', {
            pattern = 'TSUpdate',
            callback = function()
                require('nvim-treesitter.parsers').yamake = {
                    install_info = {
                        path = dir,
                        -- url = 'https://github.com/zimbulang/tree-sitter-zimbu',
                        -- location = 'parser', -- only needed if the parser is in subdirectory of a "monorepo"
                        -- generate = true, -- only needed if repo does not contain pre-generated `src/parser.c`
                        -- generate_from_json = false, -- only needed if repo does not contain `src/grammar.json` either
                        queries = 'queries/yamake', -- also install queries from given directory
                    },
                }
            end
        })
    end
}
