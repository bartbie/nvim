local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "bartbie-nvim"
version = _MODREV .. _SPECREV

test_dependencies = {
    "lua >= 5.1",
    "nvim-nio",
    "nlua",
}

source = {
    url = "git://github.com/bartbie/nvim",
}

build = {
    type = "builtin",
}
