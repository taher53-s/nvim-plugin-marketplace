vim.api.nvim_create_user_command("Marketplace", function()
  require("marketplace").open()
end, {})
