return {
  "uhs-robert/oasis.nvim",
  lazy = false,
  priority = 1000,
  keys = {
    {
      "<leader>ut",
      function()
        require("oasis").toggle_transparency()
      end,
      desc = "Toggle Transparency (Oasis)",
    },
  },
  config = function()
    require("oasis").setup() -- (see Configuration below for all customization options)
    vim.cmd.colorscheme("oasis-mirage") -- After setup, apply theme (or any style like "oasis-night")
  end,
}
