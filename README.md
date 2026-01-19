# Neovim Plugin Marketplace

A simple Neovim plugin marketplace built using Lua.  
This project explores how buffers and floating windows can be used to create an interactive, in-editor UI for discovering Neovim plugins.

The goal of this project is to gradually evolve into a full plugin marketplace with navigation, previews, and plugin management support.

---

## Current Features

- Floating window interface inside Neovim
- Dedicated buffer for marketplace content
- Displays a list of plugins using mock data
- Custom `:Marketplace` command to open the UI

---

## Getting Started (Development Setup)

### Requirements
- Neovim 0.9 or higher
- Git

### Clone the Repository

```bash
git clone https://github.com/taher53-s/nvim-plugin-marketplace.git
cd nvim-plugin-marketplace
```
---

## Run the Plugin Locally

Since this project is under development and not installed via a plugin manager yet, start Neovim with the repository added to the runtime path:

nvim --clean --cmd "set rtp+=."

Then inside Neovim, run:

:Marketplace


This will open the marketplace UI in a floating window.

---

## Project Structure

nvim-plugin-marketplace/
├── lua/
│   └── marketplace/
│       ├── init.lua        # Entry point
│       ├── ui.lua          # Floating window UI
│       ├── buffer.lua      # Buffer creation and handling
│       └── data.lua        # Mock plugin data
├── plugin/
│   └── marketplace.lua    # Defines :Marketplace command
├── README.md
└── LICENSE

## Planned Improvements
	•	Keyboard navigation (j / k, Enter)
	•	Plugin preview panel
	•	Search and filtering
	•	Integration with Lazy.nvim for installing plugins
	•	Persistent plugin metadata

