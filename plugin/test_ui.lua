local co = coroutine

local function h()
    local thread = co.running()
    -- vim.ui.select({ "red", "green", "blue" }, {}, function(choice) co.resume(thread, choice) end)
    print(co.yield(thread))
end

local g
g = function(thread)
    if co.status(thread) == "dead" then
        return
    end
    print("here")
    co.resume(thread)
    vim.schedule_wrap(g)(thread)
end

local function f()
    local thread = co.create(h)

    co.resume(thread)
    -- g(thread)
end

vim.keymap.set("n", "<bs>y", f)
