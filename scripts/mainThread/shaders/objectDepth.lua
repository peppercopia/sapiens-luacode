
local shader = {
    vertPath = "objectDepth.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
    },
}

return shader