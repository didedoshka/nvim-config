local ls = require("luasnip")

ls.add_snippets("c", {
    ls.parser.parse_snippet({ trig = "f" }, "for (int $1 = $2; $1 < $3; ++$1) {\n\t$0\n}"),
    ls.parser.parse_snippet({ trig = "fb" }, "for (int $1 = $2; $1 >= $3; --$1) {\n\t$0\n}"),
    ls.parser.parse_snippet({ trig = "en" }, "'\\n'"),
})
