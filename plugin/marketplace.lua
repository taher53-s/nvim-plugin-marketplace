local marketplace = require("marketplace")

marketplace.setup()

vim.api.nvim_create_user_command("Marketplace", function()
	marketplace.open()
end, {})
