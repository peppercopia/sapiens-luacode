
local shader = {
    vertPath = "modelImage.vert.spv",
    fragPath = "modelImage.frag.spv",
    options = {
        blendMode = "additive",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader