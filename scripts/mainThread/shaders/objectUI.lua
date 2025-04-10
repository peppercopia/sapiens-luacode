
local shader = {
    vertPath = "objectUI.vert.spv",
    fragPath = "objectUI.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader