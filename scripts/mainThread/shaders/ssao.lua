
local shader = {
    vertPath = "ssao.vert.spv",
    fragPath = "ssao.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader