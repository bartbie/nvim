vim.api.nvim_exec([[
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | execute 'CHADopen' | execute 'cd '.argv()[0]| execute 'bdelete' | endif
augroup Lightspeed
autocmd User LightspeedLeave set scrolloff=1
augroup end
]], false)
