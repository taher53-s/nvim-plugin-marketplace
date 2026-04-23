# Introduction

## Background of the Project
Extensibility is the core ethos surrounding Neovim. Advanced users leverage hundreds of individual Lua-based plugins to formulate an Integrated Development Environment (IDE). However, historically, these plugins are entirely decoupled from the editor mechanism. Finding them inherently requires external web browsers and community curations. 

## Motivation
Modern text editors like VSCode possess "Extensions" menus. This provides developers a centralized, in-editor directory that ranks, explains, and installs plugins through visual interfaces. Neovim lacks this built-in capability natively. Our motivation is to code a graphical marketplace UI inside the Neovim memory buffer using pure Lua that emulates the modern IDE experience perfectly.

## Existing System (if any)
Currently, users rely on package managers like `lazy.nvim` or `packer.nvim`. To install a package, a user must write a structured Lua command pointing explicitly to a GitHub repository owner and title. 

## Limitations of Existing Systems
1. **Zero Discovery Engine:** Package managers do not help developers discover *new* or *trending* software; they only act as a downloader for software the developer already knows.
2. **Context Switching:** Learning about a plugin requires abandoning the terminal context, swapping into a desktop web browser, and crawling GitHub.
3. **No Centralized Dashboard:** There is no visual, navigable menu to view current system states cleanly.

## Proposed Solution
The Neovim Plugin Marketplace solves this by executing network calls autonomously using background system handlers. By establishing a direct `curl` pipe into GitHub's index, the plugin populates its own virtual buffer UI. Developers can dynamically search strings, view custom information modals floating over their editor, and execute downloads visually via keybinds.
