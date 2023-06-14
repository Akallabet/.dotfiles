local nvim_web_devicons = "nvim-tree/nvim-web-devicons"

return {
  nvim_web_devicons,
  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim',  opts = {} },
  {
    -- Theme inspired by Atom
    'rose-pine/neovim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'rose-pine'
    end,
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
    },
  },
  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = "v2.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        window = {
          width = 25,
        },
        filesystem = {
          use_libuv_file_watcher = true,
          follow_current_file = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      })
    end
  },
  { 'Olical/conjure' },

  {
    'akinsho/bufferline.nvim'
  },
  -- {
  --   "romgrk/barbar.nvim",
  --   event = "BufRead",
  --   dependencies = {
  --     nvim_web_devicons
  --   },
  --   cmd = {
  --     "BufferClose",
  --     "BufferPrevious",
  --     "BufferNext",
  --   },
  -- },
  -- {
  --   'famiu/bufdelete.nvim'
  -- },
}
