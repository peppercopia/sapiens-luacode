
local shader = {
    vertPath = "objectBonedDepth.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
    },
}
return shader