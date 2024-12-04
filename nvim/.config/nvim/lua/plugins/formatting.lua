return {
  'sbdchd/neoformat',
  config = function()
    -- Neoformat config
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.css", ".html", "*.go" },
      command = 'undojoin | silent Neoformat'
    })

    vim.g.neoformat_try_node_exe = 1
  end
}
