-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>uo", Snacks.dashboard.open, { desc = "Open Start dashboard" })

-- Normal mode: Copy line down/up
-- Using `:t` prevents overwriting your yank register
vim.keymap.set("n", "<M-J>", ":t .<CR>", { desc = "Copy line down" })
vim.keymap.set("n", "<M-K>", ":t .-1<CR>", { desc = "Copy line up" })

-- Visual mode: Copy lines down/up
-- `gv` immediately re-selects the text so you can easily duplicate blocks multiple times.
vim.keymap.set("v", "<M-J>", ":t '><CR>gv", { desc = "Copy lines down" })
vim.keymap.set("v", "<M-K>", ":t '<-1<CR>gv", { desc = "Copy lines up" })

-- Normal mode: Move line down/up
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { desc = "Move line up" })

-- Visual mode: Move highlighted lines down/up
-- `gv=gv` re-selects the block, fixes the indent, and re-selects it again so you can keep moving
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move lines down" })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move lines up" })

-- Optional: Insert mode (matches VS Code behavior while typing)
vim.keymap.set("i", "<M-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<M-k>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" })
