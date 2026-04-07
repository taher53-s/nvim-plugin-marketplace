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

-- Plugin configuration (extended metadata + dependency graph)
M.plugin_configs = {
	["plenary.nvim"] = {
		desc = "Lua utility functions used by many plugins",
		repo = "https://github.com/nvim-lua/plenary.nvim",
		author = "nvim-lua",
		stars = 2500,
		category = "Utility",
		dependencies = {},  -- plenary has no deps
		priority = 50,       -- lower = loaded first
		lazy = false,        -- load immediately
		load_event = nil,    -- not lazy
	},
	["telescope.nvim"] = {
		desc = "Fuzzy finder",
		repo = "https://github.com/nvim-telescope/telescope.nvim",
		author = "nvim-telescope",
		stars = 18000,
		category = "Telescope",
		dependencies = { "plenary.nvim" },
		priority = 50,
		lazy = true,
		load_event = { event = "VeryLazy" },
	},
	["nvim-tree.lua"] = {
		desc = "File explorer",
		repo = "https://github.com/nvim-tree/nvim-tree.lua",
		author = "nvim-tree",
		stars = 12000,
		category = "File Explorer",
		dependencies = {},
		priority = 40,
		lazy = false,
		load_event = nil,
	},
	["lualine.nvim"] = {
		desc = "Status line",
		repo = "https://github.com/nvim-lualine/lualine.nvim",
		author = "nvim-lualine",
		stars = 4200,
		category = "Status Line",
		dependencies = {},
		priority = 20,
		lazy = false,
		load_event = nil,
	},
	["catppuccin.nvim"] = {
		desc = "Soothing pastel theme",
		repo = "https://github.com/catppuccin/nvim",
		author = "catppuccin",
		stars = 8900,
		category = "Colorscheme",
		dependencies = {},
		priority = 10,
		lazy = false,
		load_event = nil,
	},
	["nvim-lspconfig"] = {
		desc = "LSP configuration",
		repo = "https://github.com/neovim/nvim-lspconfig",
		author = "neovim",
		stars = 15000,
		category = "LSP",
		dependencies = {},
		priority = 30,
		lazy = true,
		load_event = { event = "LspAttach" },
	},
	["cmp.nvim"] = {
		desc = "Completion framework",
		repo = "https://github.com/hrsh7th/cmp.nvim",
		author = "hrsh7th",
		stars = 9800,
		category = "Completion",
		dependencies = {},
		priority = 50,
		lazy = true,
		load_event = { event = "InsertEnter" },
	},
	["gitsigns.nvim"] = {
		desc = "Git integration",
		repo = "https://github.com/lewis6991/gitsigns.nvim",
		author = "lewis6991",
		stars = 6200,
		category = "Git",
		dependencies = {},
		priority = 40,
		lazy = true,
		load_event = { event = "VeryLazy" },
	},
}

-- Backwards compat: legacy plugin list built from plugin_configs
M.plugins = {}
for name, config in pairs(M.plugin_configs) do
	table.insert(M.plugins, {
		name = name,
		desc = config.desc,
		repo = config.repo,
		author = config.author,
		stars = config.stars,
		category = config.category,
		dependencies = config.dependencies,
	})
end

return M
