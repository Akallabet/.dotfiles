return {
  setup = function()
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
