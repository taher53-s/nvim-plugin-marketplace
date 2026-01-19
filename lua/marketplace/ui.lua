local buffer = require("marketplace.buffer")
local data = require("marketplace.data")

local M = {}

function M.open()
  local lines = { " Neovim Plugin Marketplace ", "" }

  for _, plugin in ipairs(data.plugins) do
    table.insert(lines, "• " .. plugin.name .. " — " .. plugin.desc)
  end

  local buf = buffer.create(lines)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 60,
    height = 15,
    row = 5,
    col = 10,
    style = "minimal",
    border = "rounded",
  })
end

return M
