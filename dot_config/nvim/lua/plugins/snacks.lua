local banner = require("ascii").get_random("text", "neovim")
return {
	{
		"folke/snacks.nvim",
		opts = {
			preset = {
				header = banner,
			},
			picker = {
				win = {
					preview = {
						wo = {
							wrap = true, -- Enable soft wrapping
							linebreak = true, -- Wrap at words, not in the middle of a word
						},
					},
				},
			},
		},
	},
}
