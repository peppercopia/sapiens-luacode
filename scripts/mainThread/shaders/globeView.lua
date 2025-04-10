
local shader = {
    vertPath = "globeView.vert.spv",
    fragPath = "globeView.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader