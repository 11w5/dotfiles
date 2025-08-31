-- Minimal, fast, navigation-first Neovim setup (server-lite)
pcall(function() vim.loader.enable() end)
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
  -- File tree without devicons (lighter)
  {
    'nvim-tree/nvim-tree.lua',
    opts = {
      hijack_cursor = true,
      view = { width = 32 },
      renderer = {
        icons = { show = { file = true, folder = true, folder_arrow = true, git = false } },
      },
    },
  },

  -- Telescope lazy-loaded on demand
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find files' },
      { '<leader>fg', function() require('telescope.builtin').live_grep() end,  desc = 'Live grep' },
      { '<leader>fb', function() require('telescope.builtin').buffers() end,    desc = 'Buffers' },
      { '<leader>fh', function() require('telescope.builtin').help_tags() end,  desc = 'Help tags' },
    },
  },

  -- Treesitter: trimmed languages, no auto network installs
  {
    'nvim-treesitter/nvim-treesitter',
    event = 'BufReadPre',
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      sync_install = false,
      auto_install = false,
    },
  },

  -- Clipboard over SSH/tmux via OSC52
  { 'ojroques/nvim-osc52' },

  -- Stable lspconfig commit for 0.9.x
  { 'neovim/nvim-lspconfig', commit = '0678aa4' },
})

-- nvim-tree keymap
vim.keymap.set('n', '<leader>e', function() require('nvim-tree.api').tree.toggle({ focus = true }) end, { desc = 'Toggle file tree' })

-- Telescope mappings are declared in plugin spec to lazy-load

-- treesitter
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  sync_install = false,
  auto_install = false,
})

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
-- Quiet diagnostics for server use
vim.diagnostic.config({ virtual_text = false, update_in_insert = false, severity_sort = true })

-- LSP: only set up servers that are installed in PATH
local function has(bin)
  return vim.fn.executable(bin) == 1
end
if has('pyright-langserver') or has('basedpyright-langserver') or has('pyright') then
  lsp.pyright.setup({ on_attach = on_attach })
end
if has('typescript-language-server') then
  lsp.tsserver.setup({ on_attach = on_attach })
end

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

-- Clipboard over SSH/tmux via OSC52
pcall(function()
  require('osc52').setup({ silent = true })
  local function copy(lines, _)
    require('osc52').copy(table.concat(lines, '\n'))
  end
  local function paste()
    return { vim.split(vim.fn.getreg('+'), '\n'), vim.fn.getregtype('+') }
  end
  vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end)

