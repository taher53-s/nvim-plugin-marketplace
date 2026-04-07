# v0.8.0 — Dependency & Config System

> *Released: April 7, 2026*

## What's New

### 📦 Dependency System
- **Recursive dependency install** — Installing `telescope.nvim` automatically installs `plenary.nvim` first
- **Dependency graph** — `state.build_dependency_graph()` resolves plugin relationships
- **Cycle detection** — Safe handling of circular dependencies

### ⚙️ Configuration System
- **Plugin settings config** — Per-plugin overrides via `plugin_settings` in setup:
  ```lua
  require("marketplace").setup({
    plugin_settings = {
      ["telescope.nvim"] = {
        lazy = false,
        priority = 30,
      }
    }
  })
  ```
- **Config validation** — Type/constraint checks on `priority`, `lazy`, `load_event`, `dependencies` at setup time
- **Setup function** — Full configuration API with error reporting

### ⚡ Lazy Loading
- **Event-based deferral** — Plugins with `lazy = true` only load when their trigger event fires (e.g. `VeryLazy`, `LspAttach`, `InsertEnter`)
- **Autocmd registration** — `vim.api.nvim_create_autocmd` for deferred rtp append
- **Priority ordering** — Lower `priority` value = loaded first in `runtimepath`

### 🔌 Hooks System
- **after_install hooks** — Run custom logic after any plugin installs
- **after_uninstall hooks** — Run custom logic after any plugin uninstalls
- **register_hook / unregister_hook** — Manage hooks by name

### 🎛️ Plugin Management
- **Enable/disable toggle** — Disable a plugin without uninstalling it
- **Plugin groups** — Organize plugins by purpose: Essential, UI Enhancement, Developer Tools, Language Support, Testing

## Commits (10)

```
304ff74 Add dependency field to plugin configs with priority and lazy loading metadata
f2b2893 Implement recursive dependency collection and install_with_deps for plugin installation
8787e09 Build dependency graph system for resolving plugin relationships
4857050 Add plugin settings config system with setup function and per-plugin overrides
baaa6fd Add post-install hooks system with after_install and after_uninstall events
0c3a420 Implement lazy loading system with event-based autocmd for deferred plugin loading
bc685a1 Add enable/disable plugin toggle with is_disabled and is_enabled helpers
208e257 Add plugin load order system with priority-based runtimepath sorting
1d9ca6d Add config validation for plugin_settings with type and constraint checks
c9977b2 Add plugin grouping system with groups map and helper functions
```

## New API

```lua
-- Install with dependencies
state.install_with_deps(plugin, callback)

-- Dependency graph
local graph = state.build_dependency_graph()

-- Hooks
state.register_hook("after_install", "my_hook", function(plugin) ... end)
state.unregister_hook("after_install", "my_hook")

-- Enable/disable
state.disable_plugin(plugin)
state.enable_plugin(plugin)
state.is_disabled(plugin)  -- boolean
state.is_enabled(plugin) -- is_installed AND NOT is_disabled

-- Plugin groups
data.get_groups_for_plugin("telescope.nvim")  -- { "Essential", "Developer Tools" }
data.get_plugins_in_group("UI Enhancement")   -- { "nvim-tree.lua", "lualine.nvim", ... }
```

## Merge Instructions

```bash
cd ~/nvim-plugin-marketplace
git checkout dev && git merge feature/v0.8-dependency-system && git tag v0.8.0 && git push origin dev --tags && git checkout main && git merge feature/v0.8-dependency-system && git push origin main
```
