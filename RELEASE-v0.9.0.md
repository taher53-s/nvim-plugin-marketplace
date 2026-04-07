# v0.9.0 — Performance Engine

> *Released: April 7, 2026*

## What's New

### ⚡ Startup Performance
- **Deferred loading** — Heavy filesystem and runtimepath operations are deferred via `vim.defer_fn(50ms)` so Neovim starts faster
- **Incremental lockfile sync** — Only prunes stale lock entries, no full rebuild

### 🚀 Async & Concurrency
- **Parallel installs** — Clone up to 3 plugins concurrently with semaphore-based queue
- **Async queue system** — Limits concurrent installs to 2 to avoid overwhelming the system
- **Cached git commits** — `get_cached_commit()` avoids repeated `git rev-parse` calls

### 🎯 Rendering Optimization
- **Debounced render** — Timer-based batching (100ms) prevents redundant UI rebuilds during rapid navigation
- **Batch runtimepath append** — Uses `vim.opt.rtp:append(unpack(paths))` instead of repeated individual appends

### 📦 Caching
- **Metadata cache** — Persisted plugin metadata (stars, desc) to disk for instant load
- **Drift cache** — Pre-populated on startup for instant status display
- **Filter persistence** — Query and category survive across sessions

### 🔧 Smart Updates
- **Incremental update** — `update_outdated()` only updates plugins flagged as "Outdated" by drift detection
- **Background checker** — `checker.lua` runs async drift checks for all installed plugins in background
- **Auto-sync lockfile** — Prunes stale lock entries on setup

## Commits (10)

```
cd8d914 Add background update checker with async drift detection for all installed plugins
5739250 Add async queue system with concurrency limit and debounced UI rendering
974b0e8 Add O(1) plugin config lookup via get_plugin_config dict function
5b192b1 Add auto-sync lockfile to reconcile lock entries with installed plugins
d648dbb Add parallel install system with concurrent clones and semaphore-based queue
cb35dc5 Optimize runtimepath loading with batch append using vim.opt.rtp:append(unpack())
fb789af Reduce redundant async calls with cached git commit lookups and early-return guards
c3462c4 Add incremental update system with update_outdated that only updates drift-detected plugins
e3c009a Improve startup performance by deferring heavy filesystem and rtp operations with vim.defer_fn
6e6f8fd Optimize UI rendering with debounced render using timer-based batching
```

## New API

```lua
-- Parallel clone (max 3 concurrent)
git.clone_parallel({{ repo = "...", path = "..." }}, function(results) end)

-- Incremental update (only outdated)
state.update_outdated(function(msg) end)

-- O(1) config lookup
local cfg = state.get_plugin_config("telescope.nvim")

-- Cached commit (no repeated rev-parse)
state.get_cached_commit(path, function(ok, hash) end)

-- Auto-sync lockfile
state.sync_lockfile()
```

## Merge Instructions

```bash
cd ~/nvim-plugin-marketplace
git checkout dev && git merge feature/v0.9-performance-engine && git tag v0.9.0 && git push origin dev --tags && git checkout main && git merge feature/v0.9-performance-engine && git push origin main
```
