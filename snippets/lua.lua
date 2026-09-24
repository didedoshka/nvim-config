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
        desc = "litre task: global function, one live command",
        body = [[
function ${1:Name}()
    l.command("$2"):run()
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
local b = l.with { dir = dir }

function Build()
    b.command("cmake --build . --target " .. target):run()
end

function Run()
    Build()
    b.command("./" .. cm.executable_path(dir, target)):run()
end
l.map("r", Run)

function Debug()
    Build()
    l.debug("cpp", { program = cm.executable_path(dir, target), dir = dir })
end
$0]]
    },
}
