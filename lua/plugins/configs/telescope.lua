local ts = require("telescope")

local fzf, _ = pcall(require, "fzf_lib")
if fzf then
    ts.load_extension("fzf")
end

local extensions = {
    -- "themes",
    "file_browser",
    -- "packer",
}

for _, v in ipairs(extensions) do
    ts.load_extension(v)
end
