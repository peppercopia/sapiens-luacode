
local shader = {
    vertPath = "drawQuadTexturedMS.vert.spv",
    fragPath = "drawQuadTexturedMS.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader