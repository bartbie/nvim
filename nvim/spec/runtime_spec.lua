describe("bartbie.runtime.include", function()
    local include = require("bartbie.runtime").include

    it("checks include correctly", function()
        local patterns = { "*.lua", "test*" }
        local test_path = "test.lua"
        local gates = {
            ["or"] = true,
            ["and"] = true,
            ["xor"] = false,
            ["nor"] = false,
            ["nand"] = false,
            ["xnor"] = true,
        }

        for gate, expected in pairs(gates) do
            assert.are.same(include(gate, patterns)(test_path), expected)
        end
    end)

    local function filter(paths, gate, patterns)
        local x = vim.iter(paths):filter(include(gate, patterns)):totable()
        table.sort(x)
        return x
    end

    describe("with multiple patterns", function()
        local patterns = { "*.lua", "test*" }
        local paths = {
            "README.md",
            "config.lua",
            "main.lua",
            "src/helper.js",
            "test.txt",
            "test_runner.py",
            "test_utils.lua",
            "testing.conf",
            "tests/unit.lua",
        }

        local gates = {
            ["or"] = {
                "config.lua",
                "main.lua",
                "test.txt",
                "test_runner.py",
                "test_utils.lua",
                "testing.conf",
            },
            ["and"] = { "test_utils.lua" },
            ["xor"] = {
                "config.lua",
                "main.lua",
                "test.txt",
                "test_runner.py",
                "testing.conf",
            },
            ["nor"] = {
                "README.md",
                "src/helper.js",
                "tests/unit.lua",
            },
            ["nand"] = {
                "README.md",
                "config.lua",
                "main.lua",
                "src/helper.js",
                "test.txt",
                "test_runner.py",
                "testing.conf",
                "tests/unit.lua",
            },
            ["xnor"] = {
                "README.md",
                "src/helper.js",
                "test_utils.lua",
                "tests/unit.lua",
            },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with empty patterns", function()
        local paths = { "file1.txt", "file2.lua", "test.py" }
        local patterns = {}
        local gates = {
            ["or"] = {},
            ["and"] = {},
            ["xor"] = {},
            ["nor"] = paths,
            ["nand"] = paths,
            ["xnor"] = paths,
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with empty string patterns", function()
        local paths = { "file1.txt", "file2.lua", "test.py" }
        local patterns = { "" }
        local gates = {
            ["or"] = {},
            ["and"] = {},
            ["xor"] = {},
            ["nor"] = paths,
            ["nand"] = paths,
            ["xnor"] = paths,
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with single pattern", function()
        local patterns = { "*.lua" }
        local paths = {
            "README.md",
            "config.lua",
            "main.lua",
            "test.py",
        }
        local gates = {
            ["or"] = { "config.lua", "main.lua" },
            ["and"] = { "config.lua", "main.lua" },
            ["xor"] = { "config.lua", "main.lua" },
            ["nor"] = { "README.md", "test.py" },
            ["nand"] = { "README.md", "test.py" },
            ["xnor"] = { "README.md", "test.py" },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with complex glob patterns", function()
        local patterns = { "**/test_*.lua", "src/*.js" }
        local paths = {
            "deep/nested/test_file.lua",
            "dist/bundle.js",
            "lib/test_utils.lua",
            "src/app.js",
            "src/styles.css",
            "src/utils.js",
            "test.lua",
            "test_main.lua",
        }
        local gates = {
            ["or"] = {
                "deep/nested/test_file.lua",
                "lib/test_utils.lua",
                "src/app.js",
                "src/utils.js",
                "test_main.lua",
            },
            ["and"] = {},
            ["xor"] = {
                "deep/nested/test_file.lua",
                "lib/test_utils.lua",
                "src/app.js",
                "src/utils.js",
                "test_main.lua",
            },
            ["nor"] = {
                "dist/bundle.js",
                "src/styles.css",
                "test.lua",
            },
            ["nand"] = {
                "deep/nested/test_file.lua",
                "dist/bundle.js",
                "lib/test_utils.lua",
                "src/app.js",
                "src/styles.css",
                "src/utils.js",
                "test.lua",
                "test_main.lua",
            },
            ["xnor"] = {
                "dist/bundle.js",
                "src/styles.css",
                "test.lua",
            },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    it("preserves original order", function()
        local patterns = { "test*", "*.lua" }
        local paths = { "z.py", "test.txt", "a.lua", "test_b.py", "b.lua", "c.txt" }
        local expected = { "test.txt", "a.lua", "test_b.py", "b.lua" }

        assert.are.same(expected, vim.iter(paths):filter(include("or", patterns)):totable())
    end)
end)

describe("bartbie.runtime.exclude", function()
    local exclude = require("bartbie.runtime").exclude

    it("checks exclude correctly", function()
        local exclude = require("bartbie.runtime").exclude
        local patterns = { "*.lua", "test*" }
        local test_path = "test.lua"
        local gates = {
            ["or"] = false,
            ["and"] = false,
            ["xor"] = true,
            ["nor"] = true,
            ["nand"] = true,
            ["xnor"] = false,
        }

        for gate, expected in pairs(gates) do
            assert.are.same(exclude(gate, patterns)(test_path), expected)
        end
    end)

    local function filter(paths, gate, patterns)
        local x = vim.iter(paths):filter(exclude(gate, patterns)):totable()
        table.sort(x)
        return x
    end

    describe("with multiple patterns", function()
        local patterns = { "*.lua", "test*" }
        local paths = {
            "README.md",
            "config.lua",
            "main.lua",
            "src/helper.js",
            "test.txt",
            "test_runner.py",
            "test_utils.lua",
            "testing.conf",
            "tests/unit.lua",
        }

        local gates = {
            ["or"] = {
                "README.md",
                "src/helper.js",
                "tests/unit.lua",
            },
            ["and"] = {
                "README.md",
                "config.lua",
                "main.lua",
                "src/helper.js",
                "test.txt",
                "test_runner.py",
                "testing.conf",
                "tests/unit.lua",
            },
            ["xor"] = {
                "README.md",
                "src/helper.js",
                "test_utils.lua",
                "tests/unit.lua",
            },
            ["nor"] = {
                "config.lua",
                "main.lua",
                "test.txt",
                "test_runner.py",
                "test_utils.lua",
                "testing.conf",
            },
            ["nand"] = { "test_utils.lua" },
            ["xnor"] = {
                "config.lua",
                "main.lua",
                "test.txt",
                "test_runner.py",
                "testing.conf",
            },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with empty patterns", function()
        local paths = {
            "file1.txt",
            "file2.lua",
            "test.py",
        }
        local patterns = {}
        local gates = {

            ["or"] = paths,
            ["and"] = paths,
            ["xor"] = paths,
            ["nor"] = {},
            ["nand"] = {},
            ["xnor"] = {},
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with empty string patterns", function()
        local paths = {
            "file1.txt",
            "file2.lua",
            "test.py",
        }
        local patterns = { "" }
        local gates = {

            ["or"] = paths,
            ["and"] = paths,
            ["xor"] = paths,
            ["nor"] = {},
            ["nand"] = {},
            ["xnor"] = {},
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with single pattern", function()
        local patterns = {
            "*.lua",
        }
        local paths = {
            "README.md",
            "config.lua",
            "main.lua",
            "test.py",
        }
        local gates = {

            ["or"] = {
                "README.md",
                "test.py",
            },
            ["and"] = {
                "README.md",
                "test.py",
            },
            ["xor"] = {
                "README.md",
                "test.py",
            },
            ["nor"] = {
                "config.lua",
                "main.lua",
            },
            ["nand"] = {
                "config.lua",
                "main.lua",
            },
            ["xnor"] = {
                "config.lua",
                "main.lua",
            },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    describe("with complex glob patterns", function()
        local patterns = {
            "**/test_*.lua",
            "src/*.js",
        }
        local paths = {
            "deep/nested/test_file.lua",
            "dist/bundle.js",
            "lib/test_utils.lua",
            "src/app.js",
            "src/styles.css",
            "src/utils.js",
            "test.lua",
            "test_main.lua",
        }
        local gates = {

            ["or"] = {
                "dist/bundle.js",
                "src/styles.css",
                "test.lua",
            },
            ["and"] = {
                "deep/nested/test_file.lua",
                "dist/bundle.js",
                "lib/test_utils.lua",
                "src/app.js",
                "src/styles.css",
                "src/utils.js",
                "test.lua",
                "test_main.lua",
            },
            ["xor"] = {
                "dist/bundle.js",
                "src/styles.css",
                "test.lua",
            },
            ["nor"] = {
                "deep/nested/test_file.lua",
                "lib/test_utils.lua",
                "src/app.js",
                "src/utils.js",
                "test_main.lua",
            },
            ["nand"] = {},
            ["xnor"] = {
                "deep/nested/test_file.lua",
                "lib/test_utils.lua",
                "src/app.js",
                "src/utils.js",
                "test_main.lua",
            },
        }

        for gate, expected in pairs(gates) do
            it("works with " .. gate:upper(), function()
                assert.are.same(expected, filter(paths, gate, patterns))
            end)
        end
    end)

    it("preserves original order", function()
        local patterns = {
            "test*",
            "*.lua",
        }
        local paths = {
            "z.py",
            "test.txt",
            "a.lua",
            "test_b.py",
            "b.lua",
            "c.txt",
        }
        local expected = {
            "z.py",
            "c.txt",
        }

        assert.are.same(expected, vim.iter(paths):filter(exclude("or", patterns)):totable())
    end)
end)

require("bartbie.runtime").runtime_path():toiter():join("\n")

describe("bartbie.runtime.Path", function()
    local runtime = require("bartbie.runtime")

    local data_folder = vim.fn.stdpath("data")
    local home = vim.env.HOME

    local datas = vim.iter({ "site", "site/after", "site/pack/*/start/*" })
        :map(function(x)
            return vim.fs.joinpath(data_folder, x)
        end)
        :totable()

    local runtimes = {
        vim.fs.normalize(vim.fs.joinpath(vim.env.VIMRUNTIME, "../../../lib/nvim")),
        vim.env.VIMRUNTIME,
        (vim.fs.joinpath(vim.env.VIMRUNTIME, "/pack/dist/opt/matchit")),
        (vim.fs.joinpath(vim.env.VIMRUNTIME, "/pack/dist/opt/netrw")),
    }

    local function flat_sort(l)
        local x = vim.iter(l):flatten(math.huge):totable()
        table.sort(x)
        return x
    end

    it("matches stdpath('data') correctly", function()
        local data = {
            "/Users/test/.local/share/nvim/site",
            "/Users/test/.local/share/nvim/site/after",
            "/Users/test/.local/share/nvim/site/pack/*/start/*",
        }
        function match(x)
            return vim.glob.to_lpeg("/Users/test/.local/share/nvim/site{,/**}"):match(x)
        end

        assert(vim.iter(data):all(match))
    end)

    it("excludes stdpath('data') correctly when cleaning loiter", function()
        local data = {
            vim.fs.joinpath(data_folder, "site"),
            vim.fs.joinpath(data_folder, "site/after"),
            vim.fs.joinpath(data_folder, "site/pack/*/start/*"),
        }
        local patterns = { data_folder .. "/site{,/**}", "**/share/nvim/site{,/**}" }

        assert.are.same(data, vim.iter(data):filter(runtime.exclude("xor", patterns)):totable())
    end)

    describe("RTP", function()
        local RTP = flat_sort({
            vim.fn.stdpath("config"),
            vim.fs.joinpath(vim.fn.stdpath("config"), "after"),
            vim.env.PWD,
            vim.fs.joinpath(vim.env.PWD, "after"),
            vim.fs.joinpath(vim.env.PWD, "pack/*/start/*"),
            runtimes,
            datas,
            "/etc/xdg/nvim",
            "/etc/xdg/nvim/after",
            "/nix/store/hash123-boehm-gc-8.2.8/share/nvim/site",
            "/nix/store/hash123-boehm-gc-8.2.8/share/nvim/site/after",
            "/nix/store/hash123-cmake-3.31.7/share/nvim/site",
            "/nix/store/hash123-cmake-3.31.7/share/nvim/site/after",
            "/nix/store/hash123-compiler-rt-libc-19.1.7/share/nvim/site",
            "/nix/store/hash123-compiler-rt-libc-19.1.7/share/nvim/site/after",
            "/nix/store/hash123-fd-10.2.0/share/nvim/site",
            "/nix/store/hash123-fd-10.2.0/share/nvim/site/after",
            "/nix/store/hash123-gettext-0.22.5/share/nvim/site",
            "/nix/store/hash123-gettext-0.22.5/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3-bin/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3-bin/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3-dev/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3-dev/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3/share/nvim/site/after",
            "/nix/store/hash123-gobject-introspection-1.84.0-dev/share/nvim/site",
            "/nix/store/hash123-gobject-introspection-1.84.0-dev/share/nvim/site/after",
            "/nix/store/hash123-gobject-introspection-wrapped-1.84.0-dev/share/nvim/site",
            "/nix/store/hash123-gobject-introspection-wrapped-1.84.0-dev/share/nvim/site/after",
            "/nix/store/hash123-libcxx-19.1.7/share/nvim/site",
            "/nix/store/hash123-libcxx-19.1.7/share/nvim/site/after",
            "/nix/store/hash123-libiconv-109/share/nvim/site",
            "/nix/store/hash123-libiconv-109/share/nvim/site/after",
            "/nix/store/hash123-lix-2.93.2/share/nvim/site",
            "/nix/store/hash123-lix-2.93.2/share/nvim/site/after",
            "/nix/store/hash123-lua-5.1.5/share/nvim/site",
            "/nix/store/hash123-lua-5.1.5/share/nvim/site/after",
            "/nix/store/hash123-lua-language-server-3.15.0/share/nvim/site",
            "/nix/store/hash123-lua-language-server-3.15.0/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/nvim/site",
            "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/nvim/site",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/nvim/site",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/nvim/site/after",
            "/nix/store/hash123-lua5.2-luarocks-3.12.2-1/share/nvim/site",
            "/nix/store/hash123-lua5.2-luarocks-3.12.2-1/share/nvim/site/after",
            "/nix/store/hash123-luajit-2.1.1741730670/share/nvim/site",
            "/nix/store/hash123-luajit-2.1.1741730670/share/nvim/site/after",
            "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/nvim/site",
            "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/nvim/site/after",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/nvim/site",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/nvim/site/after",
            "/nix/store/hash123-neovim-nightly/share/nvim/site",
            "/nix/store/hash123-neovim-nightly/share/nvim/site/after",
            "/nix/store/hash123-nh-4.1.2/share/nvim/site",
            "/nix/store/hash123-nh-4.1.2/share/nvim/site/after",
            "/nix/store/hash123-nixos-rebuild/share/nvim/site",
            "/nix/store/hash123-nixos-rebuild/share/nvim/site/after",
            "/nix/store/hash123-nlohmann_json-3.11.3/share/nvim/site",
            "/nix/store/hash123-nlohmann_json-3.11.3/share/nvim/site/after",
            "/nix/store/hash123-nvim-rtp/after",
            "/nix/store/hash123-nvim-rtp/lua",
            "/nix/store/hash123-nvim-rtp/nvim",
            "/nix/store/hash123-nvim-rtp/nvim/pack/*/start/*",
            "/nix/store/hash123-pkg-config-wrapper-0.29.2/share/nvim/site",
            "/nix/store/hash123-pkg-config-wrapper-0.29.2/share/nvim/site/after",
            "/nix/store/hash123-ripgrep-14.1.1/share/nvim/site",
            "/nix/store/hash123-ripgrep-14.1.1/share/nvim/site/after",
            "/nix/store/hash123-rust-default-1.88.0/share/nvim/site",
            "/nix/store/hash123-rust-default-1.88.0/share/nvim/site/after",
            "/nix/store/hash123-unzip-6.0/share/nvim/site",
            "/nix/store/hash123-unzip-6.0/share/nvim/site/after",
            "/nix/store/hash123-vim-pack-dir",
            "/nix/store/hash123-vim-pack-dir/pack/*/start/*",
            "/nix/store/hash123-vim-pack-dir/pack/*/start/*/after",
            "/nix/store/hash123-zip-3.0/share/nvim/site",
            "/nix/store/hash123-zip-3.0/share/nvim/site/after",
            "/nix/store/hash123-zlib-1.3.1/share/nvim/site",
            "/nix/store/hash123-zlib-1.3.1/share/nvim/site/after",
            "/nix/var/nix/profiles/default/share/nvim/site",
            "/nix/var/nix/profiles/default/share/nvim/site/after",
        })

        local function createRTP()
            local rtp = vim.deepcopy(RTP)
            return runtime.createPath({
                getter = function()
                    return rtp
                end,
                setter = function(x)
                    rtp = x
                end,
            })
        end

        it("gets correctly", function()
            local p = createRTP():get()
            assert.are.same(RTP, p)
        end)

        it("cleans correctly", function()
            local p = createRTP():clean():get()
            assert.are.same(
                flat_sort({
                    datas,
                    runtimes,
                    "/nix/store/hash123-nvim-rtp/after",
                    "/nix/store/hash123-nvim-rtp/lua",
                    "/nix/store/hash123-nvim-rtp/nvim",
                    "/nix/store/hash123-nvim-rtp/nvim/pack/*/start/*",
                    "/nix/store/hash123-vim-pack-dir",
                    "/nix/store/hash123-vim-pack-dir/pack/*/start/*",
                    "/nix/store/hash123-vim-pack-dir/pack/*/start/*/after",
                }),
                flat_sort(p)
            )
        end)
    end)

    describe("PP", function()
        local dynamic_expected = {
            vim.fs.normalize(vim.fs.joinpath(vim.env.VIMRUNTIME, "../../../lib/nvim")),
            vim.env.VIMRUNTIME,
            vim.fs.joinpath(data_folder, "site"),
            vim.fs.joinpath(data_folder, "site/after"),
        }

        local PP = flat_sort({
            vim.fn.stdpath("config"),
            vim.fs.joinpath(vim.fn.stdpath("config"), "after"),
            vim.env.PWD,
            vim.fs.joinpath(vim.env.PWD, "after"),
            dynamic_expected,
            "/etc/xdg/nvim",
            "/etc/xdg/nvim/after",
            "/nix/store/hash123-boehm-gc-8.2.8/share/nvim/site",
            "/nix/store/hash123-boehm-gc-8.2.8/share/nvim/site/after",
            "/nix/store/hash123-cmake-3.31.7/share/nvim/site",
            "/nix/store/hash123-cmake-3.31.7/share/nvim/site/after",
            "/nix/store/hash123-compiler-rt-libc-19.1.7/share/nvim/site",
            "/nix/store/hash123-compiler-rt-libc-19.1.7/share/nvim/site/after",
            "/nix/store/hash123-fd-10.2.0/share/nvim/site",
            "/nix/store/hash123-fd-10.2.0/share/nvim/site/after",
            "/nix/store/hash123-gettext-0.22.5/share/nvim/site",
            "/nix/store/hash123-gettext-0.22.5/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3-bin/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3-bin/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3-dev/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3-dev/share/nvim/site/after",
            "/nix/store/hash123-glib-2.84.3/share/nvim/site",
            "/nix/store/hash123-glib-2.84.3/share/nvim/site/after",
            "/nix/store/hash123-gobject-introspection-1.84.0-dev/share/nvim/site",
            "/nix/store/hash123-gobject-introspection-1.84.0-dev/share/nvim/site/after",
            "/nix/store/hash123-gobject-introspection-wrapped-1.84.0-dev/share/nvim/site",
            "/nix/store/hash123-gobject-introspection-wrapped-1.84.0-dev/share/nvim/site/after",
            "/nix/store/hash123-libcxx-19.1.7/share/nvim/site",
            "/nix/store/hash123-libcxx-19.1.7/share/nvim/site/after",
            "/nix/store/hash123-libiconv-109/share/nvim/site",
            "/nix/store/hash123-libiconv-109/share/nvim/site/after",
            "/nix/store/hash123-lix-2.93.2/share/nvim/site",
            "/nix/store/hash123-lix-2.93.2/share/nvim/site/after",
            "/nix/store/hash123-lua-5.1.5/share/nvim/site",
            "/nix/store/hash123-lua-5.1.5/share/nvim/site/after",
            "/nix/store/hash123-lua-language-server-3.15.0/share/nvim/site",
            "/nix/store/hash123-lua-language-server-3.15.0/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/nvim/site",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/nvim/site",
            "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/nvim/site",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/nvim/site/after",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/nvim/site",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/nvim/site/after",
            "/nix/store/hash123-lua5.2-luarocks-3.12.2-1/share/nvim/site",
            "/nix/store/hash123-lua5.2-luarocks-3.12.2-1/share/nvim/site/after",
            "/nix/store/hash123-luajit-2.1.1741730670/share/nvim/site",
            "/nix/store/hash123-luajit-2.1.1741730670/share/nvim/site/after",
            "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/nvim/site",
            "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/nvim/site/after",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/nvim/site",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/nvim/site/after",
            "/nix/store/hash123-neovim-nightly/share/nvim/site",
            "/nix/store/hash123-neovim-nightly/share/nvim/site/after",
            "/nix/store/hash123-nh-4.1.2/share/nvim/site",
            "/nix/store/hash123-nh-4.1.2/share/nvim/site/after",
            "/nix/store/hash123-nixos-rebuild/share/nvim/site",
            "/nix/store/hash123-nixos-rebuild/share/nvim/site/after",
            "/nix/store/hash123-nlohmann_json-3.11.3/share/nvim/site",
            "/nix/store/hash123-nlohmann_json-3.11.3/share/nvim/site/after",
            "/nix/store/hash123-nvim-rtp/after",
            "/nix/store/hash123-nvim-rtp/nvim",
            "/nix/store/hash123-pkg-config-wrapper-0.29.2/share/nvim/site",
            "/nix/store/hash123-pkg-config-wrapper-0.29.2/share/nvim/site/after",
            "/nix/store/hash123-ripgrep-14.1.1/share/nvim/site",
            "/nix/store/hash123-ripgrep-14.1.1/share/nvim/site/after",
            "/nix/store/hash123-rust-default-1.88.0/share/nvim/site",
            "/nix/store/hash123-rust-default-1.88.0/share/nvim/site/after",
            "/nix/store/hash123-unzip-6.0/share/nvim/site",
            "/nix/store/hash123-unzip-6.0/share/nvim/site/after",
            "/nix/store/hash123-vim-pack-dir",
            "/nix/store/hash123-zip-3.0/share/nvim/site",
            "/nix/store/hash123-zip-3.0/share/nvim/site/after",
            "/nix/store/hash123-zlib-1.3.1/share/nvim/site",
            "/nix/store/hash123-zlib-1.3.1/share/nvim/site/after",
            "/nix/var/nix/profiles/default/share/nvim/site",
            "/nix/var/nix/profiles/default/share/nvim/site/after",
        })

        local function createPP()
            local pp = vim.deepcopy(PP)
            return runtime.createPath({
                getter = function()
                    return pp
                end,
                setter = function(x)
                    pp = x
                end,
            })
        end

        it("gets correctly", function()
            local p = createPP():get()
            assert.are.same(PP, p)
        end)

        it("cleans correctly", function()
            local p = createPP():clean():get()
            assert.are.same(
                flat_sort({
                    dynamic_expected,
                    "/nix/store/hash123-nvim-rtp/after",
                    "/nix/store/hash123-nvim-rtp/nvim",
                    "/nix/store/hash123-vim-pack-dir",
                }),
                flat_sort(p)
            )
        end)
    end)

    describe("luapath/package.path", function()
        local PP = flat_sort({
            vim.fs.joinpath(vim.env.PWD, "lua/?.lua"),
            vim.fs.joinpath(vim.env.PWD, "lua/?/init.lua"),
            "",
            "./?.lua",
            "./?.lua",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/lua/5.1/?.lua",
            "/nix/store/hash123-lua5.1-say-1.4.1-3/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/luajit-2.1/?.lua",
            "/nix/store/hash123-luajit-2.1.1741730670/share/luajit-2.1/?.lua",
            "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-lua-utils.nvim-1.0.2-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-lua-utils.nvim-1.0.2-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-luassert-1.9.0-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-luassert-1.9.0-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-nui.nvim-0.4.0-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-nui.nvim-0.4.0-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-nvim-nio-1.10.1-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-nvim-nio-1.10.1-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-nvim-web-devicons-0.100-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-pathlib.nvim-2.2.3-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-pathlib.nvim-2.2.3-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-plenary.nvim-scm-1/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-plenary.nvim-scm-1/share/lua/5.1/?/init.lua",
            "/nix/store/hash123-luajit2.1-say-1.4.1-3/share/lua/5.1/?.lua",
            "/nix/store/hash123-luajit2.1-say-1.4.1-3/share/lua/5.1/?/init.lua",
            "/usr/local/share/lua/5.1/?.lua",
            "/usr/local/share/lua/5.1/?.lua",
            "/usr/local/share/lua/5.1/?/init.lua",
            "/usr/local/share/lua/5.1/?/init.lua",
        })

        local function createPP()
            local pp = vim.deepcopy(PP)
            return runtime.createPath({
                getter = function()
                    return pp
                end,
                setter = function(x)
                    pp = x
                end,
            })
        end

        it("gets correctly", function()
            local p = createPP():get()
            assert.are.same(PP, p)
        end)

        it("cleans correctly", function()
            local p = createPP():clean(true):get()
            assert.are.same(
                flat_sort({
                    "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-busted-2.2.0-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-lua5.1-dkjson-2.8-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-lua-term-0.8-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-lua5.1-lua_cliargs-3.0.2-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-luassert-1.9.0-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-luasystem-0.6.3-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-lua5.1-mediator_lua-1.1.2-0/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-penlight-1.14.0-3/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-lua5.1-say-1.4.1-3/share/lua/5.1/?.lua",
                    "/nix/store/hash123-lua5.1-say-1.4.1-3/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit-2.1.1741730670/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit-2.1.1741730670/share/luajit-2.1/?.lua",
                    "/nix/store/hash123-luajit2.1-argparse-0.7.1-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-lua-utils.nvim-1.0.2-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-lua-utils.nvim-1.0.2-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-luacheck-1.2.0-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-luassert-1.9.0-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-luassert-1.9.0-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-nui.nvim-0.4.0-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-nui.nvim-0.4.0-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-nvim-nio-1.10.1-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-nvim-nio-1.10.1-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-nvim-web-devicons-0.100-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-pathlib.nvim-2.2.3-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-pathlib.nvim-2.2.3-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-plenary.nvim-scm-1/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-plenary.nvim-scm-1/share/lua/5.1/?/init.lua",
                    "/nix/store/hash123-luajit2.1-say-1.4.1-3/share/lua/5.1/?.lua",
                    "/nix/store/hash123-luajit2.1-say-1.4.1-3/share/lua/5.1/?/init.lua",
                }),
                flat_sort(p)
            )
        end)
    end)
end)
