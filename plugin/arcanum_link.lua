local M = {}

local function open_url(url)
    vim.fn.setreg("+", url)
    print(url)
end

local function open_in_arcanum(opts)
    local fname = vim.api.nvim_buf_get_name(0)
    local dirname = vim.fs.dirname(fname)
    local arc_root = vim.system({'arc', 'root'}, {cwd = dirname}):wait().stdout
    if not arc_root then
      print('arc root returned empty, not in arcadia?')
      return nil
    end

    local arc_info = vim.fn.json_decode(vim.system({'arc', 'info', '--json'}, {cwd = dirname}):wait().stdout)

    local repository = arc_info["repository"]

    local relpath = string.sub(fname, arc_root:len() + 1)
    relpath = relpath:gsub('%s+', '')

    local linenr = vim.api.nvim_win_get_cursor(0)[1]

    open_url('https://a.yandex-team.ru/' .. repository .. '/' .. relpath .. '#L' .. linenr)
end

vim.api.nvim_create_user_command(
  "ArcanumLink",
  open_in_arcanum,
  {}
)

return M
