
local shader = {
    vertPath = "cloud.vert.spv",
    fragPath = "cloud.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        alphaToCoverage = true,
    },
}

return shader