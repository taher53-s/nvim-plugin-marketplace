# Challenges & Limitations

## Problems Faced During Development

### 1. Terminal Locking and Concurrency Overflows
Initially, attempting to manage heavy backend loops processing filesystem arrays essentially froze the primary terminal interface entirely. Because of how basic Lua functions, we had to overhaul our strategy away from basic background checkers mapping native IO into utilizing non-blocking standard output streams linked to underlying POSIX `curl` instances safely triggering via scheduled polling flags asynchronously avoiding thread race conditions.

### 2. Modifiable State Restrictions
Buffer rendering inherently crashed often when trying to input new key logic natively if modifying was disabled natively. We had to strictly enclose the buffer wipe arrays (`vim.api.nvim_buf_set_lines`) between absolute `modifiable = true` security boundaries before snapping them securely to `modifiable = false` locking users out from maliciously wiping their own system structure text lines manually natively!

## Limitations of The System
- **IP API Limits**: Because the plugin queries GitHub anonymously, GitHub imposes a literal hardcap of 10 requests per entire internet gateway per minute. Extensive spamming or overly broad search parameters will flag the request system temporarily.
