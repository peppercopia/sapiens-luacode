
local shader = {
    vertPath = "modelImage.vert.spv",
    fragPath = "uiAnimatedLine.frag.spv",
    options = {
        blendMode = "additive",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader