--TODO: this could be pushed lazy even more, by adding a lspattach autocmd here
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
