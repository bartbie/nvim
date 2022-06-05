-- TODO
-- set up winbar
-- move gps from middle to winbar

local bo = vim.bo
local feline = require("feline")
local vi_mode = require("feline.providers.vi_mode")
local lsp = require("feline.providers.lsp")
local gps = require("nvim-gps")

local function get_os_icon(os)
    local icon
    if os == 'UNIX' then
        icon = ''
    elseif os == 'MAC' then
        icon = ''
    else
        icon = ''
    end
    return icon
end

-- moves mode and special buffer indicator to right if set
local to_right = nil
-- local to_right = ' '

-- darker, meshes with editor's background
-- local bg = "#1d2021"
-- lighter, makes the statusline more distinct
local bg = "#282828"

local colors = {
    bg = bg,
    black = bg,
    yellow = "#fabd2f",
    aqua = "#8ec07c",
    oceanblue = '#45707a',
    green = "#b8bb26",
    orange = "#fe8019",
    magenta = '#c14a4a',
    white = "#ebdbb2",
    fg = "#ebdbb2",
    skyblue = '#7daea3',
    red = "#fb4934",
    purple = "#d3869b",
}

local force_inactive = {
    filetypes = {
        'NvimTree',
        'dbui',
        'packer',
        'startify',
        'fugitive',
        'fugitiveblame'
    },
    buftypes = {},
    bufnames = {}
}

-- library of components to use in components table
local comps = {

    vi_mode = {
        provider = 'vi_mode',
        hl = function()
            return {
                name = vi_mode.get_mode_highlight_name(),
                bg = vi_mode.get_mode_color(),
                fg = "black",
                style = 'bold'
            }
        end,
        left_sep = to_right or '',
        right_sep = ' ',
        -- Uncomment the next line to disable icons for this component and use the mode name instead
        icon = ''
    },

    file_info = {
        provider = 'file_info',
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        },
        right_sep = ' '
    },

    file_size = {
        provider = 'file_size',
        hl = {
            fg = 'skyblue',
            bg = 'bg',
            style = 'bold'
        },
        left_sep = ' ',
    },

    file_encoding = {
        provider = 'file_encoding',
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        },
        left_sep = ' ',
        right_sep = ' '
    },

    file_type = {
        provider = 'file_type',
        hl = {
            fg = 'black',
            bg = 'aqua',
            style = 'bold'
        },
        left_sep = to_right or '',
        right_sep = ' '
    },

    file_os = {
        provider = function() return get_os_icon(bo.fileformat:upper()) end,
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        }
    },

    file_format = {
        provider = function() return bo.fileformat:upper() end,
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        },
        right_sep = ' '
    },

    git_branch = {
        provider   = 'git_branch',
        hl = {
            fg = 'yellow',
            bg = 'bg',
            style = 'bold'
        }
    },

    diff_added = {
        provider = 'git_diff_added',
        hl = {
            fg = 'green',
            bg = 'bg',
            style = 'bold'
        }
    },

    diff_changed= {
        provider = 'git_diff_changed',
        hl = {
            fg = 'orange',
            bg = 'bg',
            style = 'bold'
        }
    },

    diff_removed = {
        provider = 'git_diff_removed',
        hl = {
            fg = 'red',
            bg = 'bg',
            style = 'bold'
        },
    },

    line_percentage = {
        provider = 'line_percentage',
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        },
        right_sep = ' '
    },

    scroll_bar = {
        provider = 'scroll_bar',
        hl = {
            fg = 'yellow',
            bg = 'bg',
        },
    },

    gps = {
        provider = function() return gps.get_location() end,
        enabled = function() return gps.is_available() end,
        hl = {
            fg = 'orange',
            style = 'bold'
        }
    },

    lsp_name = {
        provider = 'lsp_client_names',
        hl = {
            fg = 'yellow',
            style = 'bold'
        },
        right_sep = ' '
    },

    diagnostics_errors = {
        provider = 'diagnostic_errors',
        enabled = function() return lsp.diagnostics_exist(vim.diagnostic.severity.ERROR) end,
        hl = {
            fg = 'red',
            style = 'bold'
        }
    },

    diagnostics_warn = {
        provider = 'diagnostic_warnings',
        enabled = function() return lsp.diagnostics_exist(vim.diagnostic.severity.WARN) end,
        hl = {
            fg = 'yellow',
            style = 'bold'
        }
    },

    diagnostics_hints = {
        provider = 'diagnostic_hints',
        enabled = function() return lsp.diagnostics_exist(vim.diagnostic.severity.HINT) end,
        hl = {
            fg = 'cyan',
            style = 'bold'
        }
    },

    diagnostics_info = {
        provider = 'diagnostic_info',
        enabled = function() return lsp.diagnostics_exist(vim.diagnostic.severity.INFO) end,
        hl = {
            fg = 'skyblue',
            style = 'bold'
        }
    },

    position = {
        provider = 'position',
        hl = {
            fg = 'white',
            bg = 'bg',
            style = 'bold'
        },
        right_sep = ' '
    }

}


-- Initialize the components table
local components = {
    active = {

        -- left
        {
            comps.vi_mode,
            comps.file_info,
            comps.git_branch,
            comps.diff_added,
            comps.diff_changed,
            comps.diff_removed,
        },

        -- mid
        {
            comps.gps,
        },

        -- right
        {
            comps.diagnostics_errors,
            comps.diagnostics_warn,
            comps.diagnostics_hints,
            comps.diagnostics_info,
            comps.file_size,
            comps.file_encoding,
            comps.file_os,
            comps.file_format,
            comps.lsp_name,
            comps.position,
            comps.line_percentage,
            comps.scroll_bar,
        },

    },

    inactive = {{comps.file_type},{}}
}

feline.setup({
    theme = colors,
    default_bg = 'bg',
    default_fg = 'fg',
    components = components,
    force_inactive = force_inactive
})

-- gruvbox's colors
-- {
--   aqua = { "#8ec07c", "108" },
--   bg0 = { "#1d2021", "234" },
--   bg1 = { "#282828", "235" },
--   bg2 = { "#282828", "235" },
--   bg3 = { "#3c3836", "237" },
--   bg4 = { "#3c3836", "237" },
--   bg5 = { "#504945", "239" },
--   bg_current_word = { "#32302f", "236" },
--   bg_diff_blue = { "#0d3138", "17" },
--   bg_diff_green = { "#32361a", "22" },
--   bg_diff_red = { "#3c1f1e", "52" },
--   bg_green = { "#b8bb26", "106" },
--   bg_red = { "#cc241d", "124" },
--   bg_statusline1 = { "#282828", "235" },
--   bg_statusline2 = { "#32302f", "235" },
--   bg_statusline3 = { "#504945", "239" },
--   bg_visual_blue = { "#2e3b3b", "17" },
--   bg_visual_green = { "#333e34", "22" },
--   bg_visual_red = { "#442e2d", "52" },
--   bg_visual_yellow = { "#473c29", "94" },
--   bg_yellow = { "#fabd2f", "172" },
--   blue = { "#83a598", "109" },
--   fg0 = { "#ebdbb2", "223" },
--   fg1 = { "#ebdbb2", "223" },
--   green = { "#b8bb26", "142" },
--   grey0 = { "#7c6f64", "243" },
--   grey1 = { "#928374", "245" },
--   grey2 = { "#a89984", "246" },
--   none = { "NONE", "NONE" },
--   orange = { "#fe8019", "208" },
--   purple = { "#d3869b", "175" },
--   red = { "#fb4934", "167" },
--   yellow = { "#fabd2f", "214" }
-- }

-- colors from nv-ide i believe, found on web
-- local colors = {
--   bg = '#282828',
--   black = '#282828',
--   yellow = '#d8a657',
--   cyan = '#89b482',
--   oceanblue = '#45707a',
--   green = '#a9b665',
--   orange = '#e78a4e',
--   violet = '#d3869b',
--   magenta = '#c14a4a',
--   white = '#a89984',
--   fg = '#a89984',
--   skyblue = '#7daea3',
--   red = '#ea6962',
-- }
