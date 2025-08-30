-- Minimal, fast, navigation-first Neovim setup
vim.g.mapleader = ' '
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 400

-- Disable netrw (let nvim-tree handle file browsing)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
local uv = vim.uv or vim.loop
if not (uv and uv.fs_stat and uv.fs_stat(lazypath)) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'nvim-tree/nvim-tree.lua', dependencies = { 'nvim-tree/nvim-web-devicons' }, opts = { hijack_cursor = true, view = { width = 32 }, renderer = { icons = { show = { file = true, folder = true, folder_arrow = true, git = false } } } } },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  { 'williamboman/mason.nvim', build = ':MasonUpdate' },
  'williamboman/mason-lspconfig.nvim',
  'neovim/nvim-lspconfig',
})

-- nvim-tree keymap
typical = true
vim.keymap.set('n', '<leader>e', function() require('nvim-tree.api').tree.toggle({ focus = true }) end, { desc = 'Toggle file tree' })

-- telescope core mappings
local tb = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', tb.live_grep,  { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', tb.buffers,    { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', tb.help_tags,  { desc = 'Help tags' })

-- treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'python', 'javascript', 'typescript', 'tsx', 'json', 'lua', 'bash', 'yaml', 'markdown', 'toml' },
  highlight = { enable = true },
  indent = { enable = true },
})

-- mason + lspconfig (pyright, tsserver)
require('mason').setup()
require('mason-lspconfig').setup({ ensure_installed = { 'pyright', 'tsserver' } })

local lsp = require('lspconfig')
local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
  map('n', 'gr', vim.lsp.buf.references, 'References')
  map('n', 'K',  vim.lsp.buf.hover, 'Hover')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format')
end

lsp.pyright.setup({ on_attach = on_attach })
lsp.tsserver.setup({ on_attach = on_attach })

-- Open tree when starting in a directory
local function open_nvim_tree(data)
  local dir = vim.fn.isdirectory(data.file) == 1
  if dir then
    require('nvim-tree.api').tree.open()
  end
end
vim.api.nvim_create_autocmd({ 'VimEnter' }, { callback = open_nvim_tree })

-- Small quality-of-life
vim.keymap.set('n', '<leader>qq', ':qall!<CR>', { desc = 'Quit all' })
