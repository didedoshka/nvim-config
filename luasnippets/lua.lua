local ls = require("luasnip")

ls.add_snippets("lua", {
    ls.parser.parse_snippet({ trig = "function" }, "function $1($2)\n\t$0\nend"),
})
