local M = {}

-- Available categories for filtering
M.categories = {
	"Utility",
	"Telescope",
	"File Explorer",
	"Status Line",
	"Colorscheme",
	"LSP",
	"Completion",
	"Git",
}

M.plugins = {
	{
		name = "plenary.nvim",
		desc = "Lua utility functions used by many plugins",
		repo = "https://github.com/nvim-lua/plenary.nvim",
		author = "nvim-lua",
		stars = 2500,
		category = "Utility",
		dependencies = {},
	},
	{
		name = "telescope.nvim",
		desc = "Fuzzy finder",
		repo = "https://github.com/nvim-telescope/telescope.nvim",
		author = "nvim-telescope",
		stars = 18000,
		category = "Telescope",
		dependencies = { "plenary.nvim" },
	},
	{
		name = "nvim-tree.lua",
		desc = "File explorer",
		repo = "https://github.com/nvim-tree/nvim-tree.lua",
		author = "nvim-tree",
		stars = 12000,
		category = "File Explorer",
		dependencies = {},
	},
	{
		name = "lualine.nvim",
		desc = "Status line",
		repo = "https://github.com/nvim-lualine/lualine.nvim",
		author = "nvim-lualine",
		stars = 4200,
		category = "Status Line",
		dependencies = {},
	},
	{
		name = "catppuccin.nvim",
		desc = "Soothing pastel theme",
		repo = "https://github.com/catppuccin/nvim",
		author = "catppuccin",
		stars = 8900,
		category = "Colorscheme",
		dependencies = {},
	},
	{
		name = "nvim-lspconfig",
		desc = "LSP configuration",
		repo = "https://github.com/neovim/nvim-lspconfig",
		author = "neovim",
		stars = 15000,
		category = "LSP",
		dependencies = {},
	},
	{
		name = "cmp.nvim",
		desc = "Completion framework",
		repo = "https://github.com/hrsh7th/cmp.nvim",
		author = "hrsh7th",
		stars = 9800,
		category = "Completion",
		dependencies = {},
	},
	{
		name = "gitsigns.nvim",
		desc = "Git integration",
		repo = "https://github.com/lewis6991/gitsigns.nvim",
		author = "lewis6991",
		stars = 6200,
		category = "Git",
		dependencies = {},
	},
}

return M
