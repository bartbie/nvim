globals = {
    "_",
    "vim",
    "describe",
    "it",
    "assert",
    "stub",
}

ignore = {
    "631", -- max_line_length
    "211/_.*", -- unused locals starting with _
    "212/_.*", -- unused args starting with _
    "213/_.*", -- unused loop vars starting with _
}

exclude_files = {
    "*/fennel/**",
}
