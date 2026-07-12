-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-clean ORPHANED swap files (the W325 "swap file already exists" warning).
-- A swap left behind by an nvim that was KILLED rather than :q-ed — e.g. the foot
-- window from a waybar/keybinding edit was closed, or `swaymsg reload` tore it
-- down — is orphaned. Re-opening the file then warns for no real reason.
-- On SwapExists we look up the swap's owner: if it was made on THIS host and its
-- PID is no longer alive, delete the stale swap and open normally (choice "d").
-- If a live nvim still holds the file (same file open twice), we leave the choice
-- unset so Neovim's normal warning still fires — that one is legitimate.
vim.api.nvim_create_autocmd("SwapExists", {
  group = vim.api.nvim_create_augroup("stale_swap_cleanup", { clear = true }),
  callback = function()
    local info = vim.fn.swapinfo(vim.v.swapname)
    if type(info) ~= "table" or info.error ~= nil then
      return -- unreadable swap: let Neovim handle it the default way
    end
    local pid = tonumber(info.pid) or -1
    local alive = false
    if pid > 0 then
      local ok, res = pcall(vim.uv.kill, pid, 0) -- signal 0 = "does this PID exist?"
      alive = ok and res == 0
    end
    if info.host == vim.uv.os_gethostname() and not alive then
      vim.v.swapchoice = "d" -- owner is gone: delete the orphaned swap, then edit
    end
  end,
})
