# v0.7.0 — Smart System

> *Released: April 7, 2026*

## What's New

### 🧠 Intelligent UI
- **Inline drift indicators** — See outdated (⬆) and untracked (⚠) plugins directly in the list
- **Smart update badge** — Top of the list shows how many updates are available
- **Background drift check** — Cache populates automatically when marketplace opens
- **Drift cache persistence** — Drift status loads instantly on subsequent opens

### 📂 Category System
- **Category filtering** — Press `c` to filter plugins by category
- **Filter persists** — Your category selection survives across sessions
- **Active filter display** — Title bar shows the active category

### ✨ UX Improvements
- **Install confirmation** — Prompts before installing (`i`)
- **Uninstall confirmation** — Prompts before removing (`u`)
- **Manual refresh** — Press `r` to clear cache and rescan
- **Plugin count** — Footer shows "Showing X of Y" when filtered
- **Expanded preview** — Shows category, stars (with comma formatting), dependencies with install status

### 🔧 Architecture
- `state.drift_cache` — In-memory cache for drift status
- `state.save_filters()` / `load_filters()` — Filter persistence
- `state.save_drift_cache()` / `load_drift_cache()` — Cache persistence to disk
- `M.clear_drift_cache()` — Clears cache and persisted file

## Commits (10)

```
d7b0d1f Add inline outdated (⬆) and untracked (⚠) indicators with drift cache system
8bf5aa5 Expand plugin metadata with category field and realistic star counts
fa5404e Upgrade preview panel layout with category, stars, dependencies, and structured metadata
9ed0920 Add manual refresh key (r) to clear drift cache and re-render
3c28227 Add smart update badge showing outdated and untracked plugin counts
c3eda67 Add category filtering system with vim.ui.select picker (c key) and active filter display
adb9550 Persist filter state (query and category) across marketplace sessions
349a1c7 Add install and uninstall confirmation prompts with vim.ui.select
02f3f97 Add filter and drift cache persistence across marketplace sessions
313cc3c Show plugin count in footer: 'Showing X of Y plugins' when filtered
```

## New Keybindings

| Key | Action |
|-----|--------|
| `i` | Install (with confirmation) |
| `u` | Uninstall (with confirmation) |
| `r` | Refresh (clear drift cache, rescan) |
| `c` | Filter by category |

## Merge Instructions

```bash
# Merge to dev
git checkout dev
git merge feature/v0.7-smart-system

# Tag
git tag v0.7.0
git push origin dev --tags

# Merge to main
git checkout main
git merge feature/v0.7-smart-system
git push origin main
```
