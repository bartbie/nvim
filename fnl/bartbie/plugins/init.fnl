(print :hello)
[
 {1 :Olical/conjure
 	:branch "master"
	;:keys { 1 "<leader>ee"
	;	2 "" }
		}
 {1 :nvim-treesitter/nvim-treesitter
 	:event [:BufReadPost :BufNewFile]
	:opts {
		:auto_install false}}
 {1 :rebelot/kanagawa.nvim
	:lazy false
	:priority 1000
	:enabled true
	:config (fn [_ opts]
		  ((. (require "kanagawa") :setup) opts)
		  (vim.cmd "colorscheme kanagawa"))}
]
