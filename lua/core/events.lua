vim.api.nvim_exec(
    [[
autocmd StdinReadPre * let s:std_in=1
augroup Lightspeed
autocmd User LightspeedLeave set scrolloff=1
augroup end
]],
    false
)
