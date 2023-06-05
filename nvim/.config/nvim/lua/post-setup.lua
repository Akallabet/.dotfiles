return {
  setup = function()
    -- Neoformat config
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.css", ".html" },
      command = 'undojoin | silent Neoformat'
    })

    vim.g.neoformat_try_node_exe = 1

    -- Neotree config
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
}
