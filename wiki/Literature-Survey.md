# Literature Survey / Related Work

## Survey of Existing Frameworks

### 1. Lazy.nvim (Package Manager)
**Summary**: The modern standard for Neovim package management. It focuses extensively on rapid caching, lazy-loading startup optimizations, and managing structured configurations.
**Core Difference**: It operates as a strict downloading engine. It possesses no capability to actively search the global ecosystem for unknown repositories.

### 2. Packer.nvim (Package Manager)
**Summary**: The legacy standard package manager. Relied on heavy compiled cache files and executed sequential blocking downloads.
**Core Difference**: Largely deprecated but fundamentally limited to the same problem as Lazy.nvim—it executes commands based on explicit string input from the user rather than facilitating interactive exploration.

### 3. VSCode Marketplace Extension API
**Summary**: The architectural layout utilized by Microsoft for Visual Studio Code. It utilizes Electron-based webviews to render HTML/CSS.
**Core Difference**: VSCode utilizes heavily graphical operating system UI layers to construct its marketplace. Because NeoVim must function perfectly inside headless terminal lines, our architecture has no access to traditional DOM manipulation. 

## Existing Tools Comparison

| Feature | Neovim Plugin Marketplace | Lazy.nvim | VSCode Marketplace |
|---------|---------------------------|-----------|--------------------|
| Engine Environment | Terminal Buffers | Terminal Buffers | Electron Webview |
| Graphical Interface | Full | Basic (Download Logs) | Full |
| Active Global Discovery | **Yes** | No | Yes |
| GitHub API Hooking | **Yes** | No | Proprietary Servers |
| Memory Footprint | Extremely Low | Medium | Very High |
