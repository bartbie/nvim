local keys = require("bartbie.G").incremental_selection
require("wildfire").setup({
    keymaps = {
        init_selection = keys.init_selection,
        node_incremental = keys.node_incremental,
        node_decremental = keys.node_decremental,
        scope_incremental = keys.scope_incremental,
    },
})
