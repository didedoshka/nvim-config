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

    {
        prefix = "litre_cmake",
        desc = "whole .litre.lua for a cmake project: xV lists the executable targets",
        body = [[
local l = require("litre")
local cm = require("litre.cmake")
local dir = "${1:build}"
local target = l.param("target", function() return cm.executables(dir) end)
local b = l.env { dir = dir }

function Build()
    b.sh("cmake --build . --target " .. target)
end

function Run()
    Build()
    b.sh("./" .. cm.executable_path(dir, target))
end
l.map("r", Run)

function Debug()
    Build()
    l.debug("cpp", { program = cm.executable_path(dir, target), dir = dir })
end
$0]]
    },
}
