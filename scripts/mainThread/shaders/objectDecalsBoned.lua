
local shader = {
    vertPath = "objectDecalsBoned.vert.spv",
    fragPath = "objectDecals.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "disabled",
    },
}

return shader