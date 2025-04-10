
local shader = {
    vertPath = "ssaoBlur.vert.spv",
    fragPath = "ssaoBlur.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader