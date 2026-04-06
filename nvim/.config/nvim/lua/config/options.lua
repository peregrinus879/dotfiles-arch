-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false

local uv = vim.uv or vim.loop
local overlay = vim.fn.stdpath("config") .. "/lua/config/overlay.lua"

-- Allow environment overlays to extend shared options without replacing them.
if uv.fs_stat(overlay) then
  require("config.overlay").setup()
end
