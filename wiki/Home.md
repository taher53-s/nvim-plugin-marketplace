# Project Overview

## Project Title
**Neovim Plugin Marketplace**: A Sweet & Simple Native Architecture

## Team Members
- **Taher Sohagpurwala** | App ID: **2409540** | GitHub: **[taher53-s](https://github.com/taher53-s)**

## Guide / Faculty Name
**Yogesh Jadhav**

## Project Domain
Open Source Software Development / Developer Tooling

## Short Description
The Neovim Plugin Marketplace is a robust, lightweight graphical interface enabling developers to dynamically search, install, update, and manage Neovim plugins directly from within the editor via GitHub's global REST API. Built natively in Lua, it replaces traditional terminal-based configuration files with an interactive, dual-state GUI dashboard.

## Problem Statement
Neovim is vastly customizable but handles plugin management primarily through hard-coded Lua configurations. This requires developers to leave their coding workflows, manually search GitHub in a browser for the repository strings, and paste them into configuration files before running sync commands. There is a lack of an immersive, centralized graphical search engine integrated natively inside Neovim.

## Objectives
- To bridge the gap between GitHub's massive plugin ecosystem and the Neovim editor.
- To provide an interactive graphical UI inside terminal buffers natively without external graphical dependencies.
- To execute asynchronous networking requests so the developer's typing speed is never blocked during downloads.

## Key Features
- **Live Search Engine**: Directly interrogates the live `api.github.com` index.
- **Dual-State Model**: Visually segments installed plugins from trending global recommendations.
- **Async Graphical Loaders**: Intercepts `git clone` raw output arrays, converting downloading operations into rendering ASCII progress bars.
- **API Filters**: Built-in functionality for querying repositories based on Best Matches, Start counts, and strict `neovim-plugin` topic tags.
