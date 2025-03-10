return {
  setup = function()
    local leader = ''

    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '
    -- Quality of life
    vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
    vim.keymap.set({ 'n', 'v' }, '<leader><CR>', ':noh<CR>', { silent = true })
    vim.keymap.set({ 'n', 'v' }, '<leader>p', '"_dP', { silent = true })
    vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
    vim.keymap.set({ 'n', 'v' }, '<leader>pm', function() vim.o.relativenumber = not vim.o.relativenumber end,
      { silent = true, desc = 'Pairing mode' })
    vim.keymap.set('n', '<C-d>', '<C-d>zz')
    vim.keymap.set('n', '<C-u>', '<C-u>zz')
    vim.keymap.set('n', 'n', 'nzz')
    vim.keymap.set('n', 'N', 'Nzz')

    -- Diagnostic keymaps
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

    -- Telescope
    vim.keymap.set('n', '<leader>?', function() require('telescope.builtin').oldfiles() end,
      { desc = '[?] Find recently opened files' })
    vim.keymap.set('n', '<leader><space>', function()
      require('telescope.builtin').buffers()
    end, { desc = '[ ] Find existing buffers' })
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>ff', function()
      require('telescope.builtin').find_files({
        find_command = { 'rg', '--files', '--hidden', '-g', '!.git' },
      })
    end, { desc = '[F]ind [F]iles' })
    vim.keymap.set('n', '<leader>fh', function() require('telescope.builtin').help_tags() end, { desc = '[F]ind [H]elp' })
    vim.keymap.set('n', '<leader>fw', function() require('telescope.builtin').grep_string() end,
      { desc = '[F]ind current [W]ord' })
    vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end,
      { desc = '[F]ind by [G]rep' })
    vim.keymap.set('n', '<leader>fd', function() require('telescope.builtin').diagnostics() end,
      { desc = '[F]ind [D]iagnostics' })

    -- Fugitive
    vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = "Git status" })

    -- Neotree
    vim.keymap.set({ 'n', 'v' }, '<leader>n', ':Neotree toggle<CR>', { silent = true })

    vim.keymap.set({ 'n', 'v' }, 'H', ':BufferPrevious<CR>', { silent = true })
    vim.keymap.set({ 'n', 'v' }, 'L', ':BufferNext<CR>', { silent = true })
    vim.keymap.set({ 'n', 'v' }, '<leader>bc', ':BufferClose<CR>', { silent = true })
  end
}
