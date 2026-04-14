local augroup = require("bartbie.augroup")
local ts = vim.treesitter

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("ts_enable"),
    pattern = { "*" },
    callback = function(args)
        local buf = args.buf
        local ft = vim.bo[buf].filetype
        local lang = ts.language.get_lang(ft)
        -- load the parser
        if not (lang and ts.language.add(lang)) then
            return
        end

        -- bootstrap folds
        -- CORRECTNESS: attach before ts.start so on_changedtree catches first parse
        local fold = require("bartbie.fold")
        fold.attach(buf)

        -- hl
        ts.start(buf, lang)
        -- turn on folds
        vim.wo[0][0].foldmethod = "expr"
        vim.wo[0][0].foldexpr = "v:lua.require'bartbie.fold'.foldexpr()"

        -- nvim-treesitter indents
        if pcall(require, "nvim-treesitter") then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
