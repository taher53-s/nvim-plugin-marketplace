local M = {}

M.plugins = {
	{
		name = "plenary.nvim",
		desc = "Lua utility functions used by many plugins",
		repo = "https://github.com/nvim-lua/plenary.nvim",
		author = "nvim-lua",
		stars = 0,
	},
	{
		name = "telescope.nvim",
		desc = "Fuzzy finder",
		repo = "https://github.com/nvim-telescope/telescope.nvim",
		author = "nvim-telescope",
		stars = 0,
		dependencies = { "plenary.nvim" },
	},
	{
		name = "nvim-tree.lua",
		desc = "File explorer",
		repo = "https://github.com/nvim-tree/nvim-tree.lua",
		author = "nvim-tree",
		stars = 0,
	},
	{
		name = "lualine.nvim",
		desc = "Status line",
		repo = "https://github.com/nvim-lualine/lualine.nvim",
		author = "nvim-lualine",
		stars = 0,
	},
}

return M
