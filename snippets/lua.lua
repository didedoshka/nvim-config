return {
    {
        prefix = "brd",
        body = [[
$1 = {
    dir = "$2",
    build = "$3",
    run = "$4",
},
]]
    },

    {
        prefix = "brd_debug",
        body = [[
$1 = {
    dir = "$2",
    build = "$3",
    run = "$4",
    debug = {
        configuration = "$5",
        executable = "$6"
    }
},
]]
    }
}
