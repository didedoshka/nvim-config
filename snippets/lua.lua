-- .litre.lua building blocks (litre.nvim; readme.md there is the spec)
return {
    {
        prefix = "litre",
        desc = ".litre.lua header",
        body = [[local l = require("litre")
$0]]
    },

    {
        prefix = "task",
        desc = "litre task: global function, sh streams into its buffer",
        body = [[
function ${1:Name}()
    l.sh("$2")
end
$0]]
    },

    {
        prefix = "param",
        desc = "litre param: literal list, xV picks and writes new values back",
        body = [[local ${1:name} = l.param("$1", { "$2" })$0]]
    },
}
