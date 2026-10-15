-- .liter.lua building blocks (liter.nvim; readme.md there is the spec)
return {
    {
        prefix = "liter_header",
        desc = ".liter.lua header",
        body = [[local l = require("liter")
$0]]
    },

    {
        prefix = "liter_task",
        desc = "liter task: global function, one live command",
        body = [[
function ${1:Name}()
    l.command("$2"):run()
end
$0]]
    },

    {
        prefix = "liter_parameter",
        desc = "liter parameter: literal list, picked in the x layer, new values written back",
        body = [[local ${1:name} = l.parameter("$1", { "$2" })$0]]
    },

    {
        prefix = "liter_cmake",
        desc = "whole .liter.lua for a cmake project: the target param lists the executables",
        body = [[
local l = require("liter")
local cm = require("liter.cmake")
local dir = "${1:build}"
local target = l.parameter("target", function() return cm.executables(dir) end)
local b = l.with { dir = dir }

function Build()
    b.command("cmake --build . --target " .. target):run()
end

function Run()
    Build()
    b.command("./" .. cm.executable_path(dir, target)):run()
end

function Debug()
    Build()
    l.debug("cpp", { program = cm.executable_path(dir, target), dir = dir })
end
$0]]
    },
}
