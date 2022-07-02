local pluginList = {
    impatient = { "lewis6991/impatient.nvim" },

    gruvbox = {
        "sainnhe/gruvbox-material",
        config = function()
            require("plugins.configs.gruvbox")
        end,
    },

    nvim_tree = {
        "kyazdani42/nvim-tree.lua",
        requires = {
            "kyazdani42/nvim-web-devicons", -- optional, for file icon
        },
        tag = "nightly", -- optional, updated every week. (see issue #1193)
        config = function()
            require("plugins.configs.nvimtree")
        end,
    },

    fugitive = { "tpope/vim-fugitive" },

    treesitter = {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        config = function()
            require("plugins.configs.treesitter")
        end,
    },

    coq = {
        "ms-jpq/coq_nvim",
        branch = "coq",
        {
            "ms-jpq/coq.artifacts",
            branch = "artifacts",
        },

        {
            "ms-jpq/coq.thirdparty",
            branch = "3p",
            config = function()
                require("plugins.configs.coq")
            end,
        },
    },

    lsp = {
        "williamboman/nvim-lsp-installer",
        after = { "coq_nvim" },
        {
            "neovim/nvim-lspconfig",
            config = function()
                require("plugins.configs.lsp")
            end,
        },
    },

    telescope = {
        "nvim-telescope/telescope.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            run = "make",
            cond = vim.fn.executable("make") == 1,
        },
        {
            "nvim-telescope/telescope-file-browser.nvim",
            config = function()
                require("plugins.configs.telescope")
            end,
        },
    },

    gitsigns = {
        "lewis6991/gitsigns.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        after = "vim-fugitive",
        config = function()
            require("plugins.configs.gitsigns")
        end,
        -- tag = 'release' -- To use the latest release
    },

    comment = {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    surround = { "tpope/vim-surround" },

    unimpaired = { "tpope/vim-unimpaired" },

    vim_repeat = { "tpope/vim-repeat" },

    nrpattern = {
        "zegervdv/nrpattern.nvim",
        config = function()
            require("nrpattern").setup()
        end,
    },

    dadbot = { "tpope/vim-dadbod" },

    dadbot_ui = { "kristijanhusak/vim-dadbod-ui", after = { "vim-dadbod", "vim-dadbod-completion" } },

    dadbot_autocompletion = { "kristijanhusak/vim-dadbod-completion", after = "vim-dadbod" },

    lightspeed = { "ggandor/lightspeed.nvim" },

    themer = {
        "themercorp/themer.lua",
    },

    indent_blackline = {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("plugins.configs.indent_blackline")
        end,
    },

    nvim_gps = {
        "SmiteshP/nvim-gps",
        requires = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("nvim-gps").setup()
        end,
    },

    feline = {
        "feline-nvim/feline.nvim",
        requires = { "kyazdani42/nvim-web-devicons" },
        after = "nvim-gps",
        config = function()
            require("plugins.configs.feline")
        end,
    },

    colorizer = {
        "norcalli/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup()
        end,
    },

    dressing = {
        "stevearc/dressing.nvim",
    },

    notify = {
        "rcarriga/nvim-notify",
        config = function()
            vim.notify = require("notify")
        end,
    },

    hlslens = {
        "kevinhwang91/nvim-hlslens",
    },

    scrollbar = {
        "petertriho/nvim-scrollbar",
        config = function()
            require("plugins.configs.scrollbar")
        end,
    },

    trouble = {
        "folke/trouble.nvim",
        requires = "kyazdani42/nvim-web-devicons",
        config = function()
            require("plugins.configs.trouble")
        end,
    },
    bufferline = {
        "akinsho/bufferline.nvim",
        tag = "v2.*",
        requires = "kyazdani42/nvim-web-devicons",
        config = function()
            require("plugins.configs.bufferline")
        end,
    },

    lspsaga = {
        "tami5/lspsaga.nvim",
        config = function()
            require("plugins.configs.lspsaga")
        end,
    },

    whichkey = {
        "folke/which-key.nvim",
        config = function()
            require("plugins.configs.which-key")
        end,
    },

    alpha = {
        "goolord/alpha-nvim",
        config = function()
            require("plugins.configs.alpha")
        end,
    },

    dap = {
        "mfussenegger/nvim-dap",

        {
            "rcarriga/nvim-dap-ui",
            config = function()
                require("dapui").setup()
            end,
        },

        {
            "theHamsta/nvim-dap-virtual-text",
            config = function()
                require("nvim-dap-virtual-text").setup()
            end,
        },
    },
}

return pluginList
