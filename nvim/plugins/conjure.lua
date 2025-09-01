local c = require("bartbie.vimg").create_config("conjure")
c.filetype.scheme = "conjure.client.scheme.stdio"
c.client.scheme.stdio = {
    command = "petite",
    prompt_pattern = "> $",
    value_prefix_pattern = false,
}
-- TODO: remap conjure
c.mapping.doc_word = "gk"

c:commit_all()
