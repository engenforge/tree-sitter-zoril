-- Zoril Language Configuration for Neovim
-- 
-- 1. Filetype detection:
--    Place in ~/.config/nvim/ftdetect/zoril.lua (or inside your init.lua)
vim.filetype.add({
  extension = {
    zrl = 'zoril',
  },
})

-- 2. Optional: nvim-treesitter integration
--    If using nvim-treesitter to manage parsers:
local ok, parsers = pcall(require, "nvim-treesitter.parsers")
if ok then
  local parser_config = parsers.get_parser_configs()
  parser_config.zoril = {
    install_info = {
      url = "https://git.engenforge.com/tree-sitter-zoril.git",
      files = { "src/parser.c", "src/scanner.c" },
      branch = "main",
      generate_requires_npm = false,
      requires_generate_from_grammar = false,
    },
    filetype = "zrl",
  }
end
