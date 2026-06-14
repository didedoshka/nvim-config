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
                local available_langs = require('nvim-treesitter').get_available()
                local is_available = vim.tbl_contains(available_langs, lang)
                if is_available then
                    require('nvim-treesitter').install(lang):wait()
                    vim.treesitter.start()
                end
            end,
        })

        vim.filetype.add({
            filename = {
                ["ya.make"] = "yamake",
            },
        })

        local dir = vim.fn.expand("~/arc/devtools/ide/tree-sitter-yamake")
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
