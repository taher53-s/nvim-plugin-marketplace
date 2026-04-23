# Methodology / Working

## System Execution Flow

### 1. Initialization Core
When a user executes `:Marketplace`, the `init.lua` entrypoint executes the `ui.open()` stack. The application instantly triggers `sync_installed_from_filesystem()` to scan all directories under the system's runtime path natively, loading installed packages into RAM.

### 2. Autonomous Global Fetching
If the UI detects a completely blank uninitialized array for `recommended` software, it automatically spawns an asynchronous `api.search_github` protocol targeting the `topic:neovim-plugin+sort:stars` parameters, forcing the GitHub ecosystem to do all backend sorting before fetching.

### 3. Progressive Rendering Algorithm
For downloading packages visually, the system relies on an ingenious workaround. 
Because Neovim plugins execute essentially on a single process thread, downloading software manually freezes the editor.
Our methodology implements `vim.system()` bindings injected solely into the `stderr` string loops. 
We utilize pattern matching (`data:match("Receiving objects:%s*(%d+)%%")`) to strip graphical string percentages exclusively formatted from the `git clone` protocols directly to memory.

The `buffer.lua` file is then triggered asynchronously to intercept the new percentage and print visual ASCII blocks representing data integrity mathematically (`math.floor(prog / 10)`).
