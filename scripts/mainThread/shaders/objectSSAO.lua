
local shader = {
    vertPath = "objectSSAO.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader