local g = vim.g
local o = vim.o
local cmd = vim.cmd

-- Gruvbox-material
local palettes = {"material", "mix", "original"}
local backgrounds = {"hard", "medium", "soft"}
local modes = {"light", "dark"}

-- lua starts from 1
local palette = palettes[3]
local background = backgrounds[1]
local mode = modes[2]


o.background = mode
g.gruvbox_material_background = background
g.gruvbox_material_palette = palette

g.gruvbox_material_disable_italic_comment = 0
g.gruvbox_material_enable_bold = 1
g.gruvbox_material_enable_italic = 1
g.gruvbox_material_cursor = "auto"
g.gruvbox_material_transparent_background = 0
-- g.gruvbox_material_visual = "grey background"
-- g.gruvbox_material_selection_background = "grey"
g.gruvbox_material_sign_column_background = "none"
g.gruvbox_material_spell_foreground = 'none'
g.gruvbox_material_ui_contrast = 'low'
g.gruvbox_material_show_eob = 0
g.gruvbox_material_diagnostic_text_highlight = 0
g.gruvbox_material_diagnostic_line_highlight = 1
g.gruvbox_material_diagnostic_virtual_text = 1
g.gruvbox_material_current_word = 'grey background'
g.gruvbox_material_disable_terminal_colors = 0
g.gruvbox_material_statusline_style = "original"
g.gruvbox_material_lightline_disable_bold = 0

cmd('colorscheme gruvbox-material')
