
local shader = {
    vertPath = "objectDecalsDepth.vert.spv",
    fragPath = "objectDecalsDepth.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        alphaToCoverage = true,
    },
}

return shader