local g = vim.g
local cmd = vim.cmd

g.sonokai_style = 'atlantis'
g.sonokai_enable_italic = true
g.sonokai_disable_italic_comment = true
g.sonokai_show_eob = false
g.sonokai_diagnostic_text_highlight = true
g.sonokai_diagnostic_line_highlight = true
g.sonokai_diagnostic_virtual_text = 'colored'

cmd('colorscheme sonokai')
