require("bartbie.runtime").run_once(function()
    require("nio").run(function()
        local json = require("bartbie.resrc").read_json("pyrightconfig.json")
        vim.lsp.config("basedpyright", {
            settings = {
                basedpyright = {
                    analysis = {
                        diagnosticSeverityOverrides = json,
                    },
                },
            },
        })
    end)
end)
