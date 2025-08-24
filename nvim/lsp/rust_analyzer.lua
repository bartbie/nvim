return {
    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },
            check = {
                command = "clippy",
            },
            checkOnSave = true,
        },
    },
}
